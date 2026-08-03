---
layout: post
title: "Cloudflare R2 + Active Storage: every error I hit, and the fix"
author: Yaroslav Shmarov
tags: ruby-on-rails active-storage cloudflare-r2 s3 file-uploads kamal
thumbnail: /assets/thumbnails/aws.png
---

Cloudflare R2 is S3-compatible object storage with **zero egress fees** and a free custom domain in front of Cloudflare's CDN. For a Rails app on a single Hetzner box behind Kamal, that is exactly what you want: uploads leave the server, images are served from a PoP near the user, and the bandwidth bill does not scale with traffic.

"S3-compatible" is doing a lot of work in that sentence. R2 is compatible enough that `aws-sdk-s3` talks to it, and *incompatible* in three or four specific places that Active Storage steps on immediately. My git log for the night I switched over reads:

```
01:07  Switch ActiveStorage from Hetzner to Cloudflare R2
01:13  Remove unsupported public_url option
01:17  Rewrite ActiveStorage public URLs to the R2 custom domain
01:25  Fix R2 initializer crash during Docker build
01:32  Update CSP connect-src for R2
01:38  Fix R2 direct uploads: remove ACL and fix CSP domain
01:39  Rescue ArgumentError during Docker build
01:44  Fix R2 ACL stripping: override upload_options method
01:56  cleanup r2 config
02:04  Update storage.yml
02:17  try fix R2
```

Seventy minutes, eleven commits, and the last one is called `try fix R2`. Then four months later it broke again for a completely different reason.

Here is the whole thing: the config that works, then every error in the order I hit it.

## The working setup

### 1. The gem

R2 speaks the S3 API, so you use Active Storage's S3 service and the AWS SDK — there is no `aws-sdk-r2`:

```ruby
# Gemfile
gem "aws-sdk-s3", "~> 1.225", require: false
```

`require: false` is the Rails default here — Active Storage requires it lazily, only when the S3 service is actually built.

### 2. Credentials

```bash
rails credentials:edit
```

```yaml
cloudflare_r2:
  access_key_id: ...
  secret_access_key: ...
  account_id: ...
  bucket: myapp
```

Create the API token in the Cloudflare dashboard under **R2 → API → Manage API tokens**, scoped to **Object Read & Write** on that one bucket. The `account_id` is the R2 account hash shown in the bucket's S3 API endpoint.

### 3. `config/storage.yml`

```yaml
cloudflare:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:cloudflare_r2, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:cloudflare_r2, :secret_access_key) %>
  endpoint: https://<%= Rails.application.credentials.dig(:cloudflare_r2, :account_id) %>.r2.cloudflarestorage.com
  bucket: <%= Rails.application.credentials.dig(:cloudflare_r2, :bucket) %>
  region: auto
  public: true
  request_checksum_calculation: when_required
  response_checksum_validation: when_required
```

```ruby
# config/environments/production.rb
config.active_storage.service = :cloudflare
```

Note `region: auto` — R2 has no regions, but the SDK insists on a value.

Development stays on local disk (`config.active_storage.service = :local`). I only point dev at R2 deliberately, when I need to reproduce something R2-specific — which is the *only* reason `http://localhost:3000` is in the bucket's CORS list below.

### 4. The compatibility initializer

```ruby
# config/initializers/active_storage_cloudflare_r2.rb
# frozen_string_literal: true

# Cloudflare R2 compatibility for the ActiveStorage S3 service.
#
# Two issues with R2 + `public: true`:
# 1. Public URLs use the S3 API endpoint which requires auth — rewrite to cdn.myapp.com
# 2. R2 doesn't support object-level ACLs — strip the `acl: "public-read"` that
#    ActiveStorage hard-codes when `public: true` is set

Rails.application.config.after_initialize do
  if Rails.configuration.active_storage.service == :cloudflare
    require "active_storage/service/s3_service"
    ActiveStorage::Service::S3Service.prepend(Module.new do
      def public_url(key, **)
        "https://cdn.myapp.com/#{key}"
      end

      # R2 rejects object-level ACLs — strip from all uploads and direct upload presigned URLs
      def upload_options
        super.except(:acl)
      end
    end)
  end
rescue NameError, LoadError
  # S3Service unavailable during Docker build (asset precompilation with dummy credentials)
end
```

### 5. Bucket settings in the Cloudflare dashboard

Two things that live **only** in the dashboard and will silently sink you:

- **Custom domain** — bucket → **Settings → Public access → Custom domains** → connect `cdn.myapp.com`. This is what makes the bucket publicly readable and CDN-cached. Add the DNS record in the same Cloudflare account and it is provisioned for you.
- **CORS policy** — bucket → **Settings → CORS policy**. Required for browser direct uploads:

```json
[
  {
    "AllowedOrigins": ["https://app.myapp.com", "http://localhost:3000"],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

### 6. Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
policy.connect_src :self,
                   "https://cdn.myapp.com",
                   "https://myapp.<account_id>.r2.cloudflarestorage.com"
```

That's the working state. Now the errors.

## Error 1: `public_url` is not a storage.yml option

R2's docs and half the blog posts about it suggest a `public_url:` key. Active Storage's S3 service does not extract it — it splats unknown options straight into the AWS SDK client, which rejects them. The app **crashes on boot in production**, after a green deploy, with an `ArgumentError` from `Aws::S3::Resource`.

There is no config key for "serve public files from this other domain". You have to override the method (error 2).

## Error 2: public URLs point at the S3 API endpoint

With `public: true`, Active Storage calls `object.public_url`, and the aws-sdk builds that from your `endpoint:` — so every `url_for(user.avatar)` returned:

```
https://myapp.<account_id>.r2.cloudflarestorage.com/abc123...
```

That is the **authenticated S3 API**, not a public bucket. Every image on the site was a broken icon; opening one directly gives an XML `Unauthorized` / `InvalidArgument` body. Nothing in the Rails log, because Rails did its job — the browser is the one getting the 401.

The fix is the `public_url` override above, pointed at the custom domain. Prepend a module rather than reopening `S3Service`, so `super` still exists if you ever want the original.

## Error 3: R2 rejects object-level ACLs

The one that cost the most time, because it breaks uploads in two different places.

When `public: true` is set, Active Storage hard-codes `acl: "public-read"` into its upload options. S3 supports that. R2 **does not implement object ACLs at all** — access is a property of the bucket. So R2 refuses the request, and you get:

- server-side uploads (`attach` on a local file) failing with an SDK error
- **direct uploads failing in the browser** — a 400 on the PUT to R2, because the ACL is baked into the presigned URL that Rails handed the client

My first fix was wrong in an interesting way:

```ruby
# Doesn't reliably work
service = ActiveStorage::Blob.service
service.upload_options.delete(:acl) if service.respond_to?(:upload_options)
```

Mutating the already-built service instance from an initializer depends on when the service got built relative to your initializer, and on nothing else re-reading the config later. It also gave me a *new* Docker build failure (error 4), because `ActiveStorage::Blob.service` instantiates the service — which needs real credentials.

Overriding the method instead is order-independent and covers presigned URLs too:

```ruby
def upload_options
  super.except(:acl)
end
```

## Error 4: the initializer crashes the Docker build

`docker build` runs `assets:precompile`, which boots the Rails app with a **dummy** `RAILS_MASTER_KEY` or none at all. Anything in an initializer that touches real credentials or instantiates the storage service explodes there — and the deploy fails at build time, before it ever reaches the server.

I went through two rounds of this: first `NameError`/`LoadError` (the S3 service class not being loadable), then `ArgumentError` (the service refusing to instantiate without credentials). I patched the rescue list twice before fixing the actual cause:

**Don't instantiate the service at boot.** Check the *config symbol*, not the built object:

```ruby
if Rails.configuration.active_storage.service == :cloudflare
```

That reads a symbol from config. No credentials, no client, no network. The `rescue NameError, LoadError` stays as a cheap belt-and-braces for the build environment.

## Error 5: `501 Not Implemented` from the checksum headers

This is the one that made me delete the entire compatibility layer at 01:56 to isolate the variable, then put it back at 02:17 once I understood it.

Recent `aws-sdk-s3` versions (1.178+) send **CRC32 checksums by default** on uploads, using a streaming trailer. R2 did not implement that, so requests came back `501 Not Implemented` — a bewildering error, because it reports the *service* as broken, and it appears only after you upgrade a gem you weren't thinking about.

Two client options turn it off:

```yaml
request_checksum_calculation: when_required
response_checksum_validation: when_required
```

These are `aws-sdk-core` client options and pass straight through `storage.yml`. R2 has since improved checksum support, but I still set both — they cost nothing and this failure mode is miserable to diagnose.

> Honest caveat: this commit of mine has no message, so I'm reconstructing intent from what the two options do. The behaviour is well documented; my exact error string that night is not recorded.

## Error 6: the CSP host is not the host you think

Direct uploads PUT from the browser, so the R2 host needs to be in `connect_src`. My first attempt used the endpoint from `storage.yml`:

```ruby
"https://<account_id>.r2.cloudflarestorage.com"          # wrong
```

But the SDK presigns **virtual-hosted style**, with the bucket as a subdomain:

```ruby
"https://myapp.<account_id>.r2.cloudflarestorage.com"    # right
```

CSP host matching does not treat a bare host as a wildcard for its subdomains, so the first version blocked every upload. Symptom: the request never appears in any server log and the browser console shows a CSP violation. Read the console, not the logs.

Also add your `cdn.myapp.com` to `connect_src` if any JS fetches from it.

## Error 7 (four months later): bucket CORS after a domain change

The uploads worked for months. Then I renamed the app, moved it from `hypemarket.ai` to `app.paidcollabs.com`, and a few weeks later a bug report: "file upload broken".

Root cause was **infra, not code**. The R2 bucket's CORS policy still allowed only the *old* origins, so the browser preflight failed before the PUT. Nothing in the Rails codebase mentions bucket CORS — it lives in the Cloudflare dashboard, so it isn't in the diff, isn't in code review, and isn't in any migration checklist you wrote for the code.

Fixed live via the Cloudflare API (`PUT /accounts/<account_id>/r2/buckets/<bucket>/cors`) with no deploy, then verified with a preflight probe:

```bash
curl -i -X OPTIONS "https://myapp.<account_id>.r2.cloudflarestorage.com/probe" \
  -H "Origin: https://app.myapp.com" \
  -H "Access-Control-Request-Method: PUT"
```

You want `Access-Control-Allow-Origin` echoing your origin in the response. If it's absent, the browser will refuse the upload no matter how correct your Rails config is.

**Add "update R2 bucket CORS origins" to your domain-migration checklist.** Everything else about the move was in git; this one thing wasn't, and it cost weeks of broken uploads before someone reported it.

## Error 8: direct upload URLs expiring mid-transfer

Active Storage presigns direct upload URLs for **5 minutes**. That is generous for a fast connection and not remotely enough for a 300 MB video over hotel wifi, or when a proxy buffers the upload before forwarding it. The upload just dies near the end.

```ruby
# config/initializers/active_storage_direct_upload_expiry.rb
# frozen_string_literal: true

module ActiveStorage
  mattr_accessor :service_urls_for_direct_uploads_expire_in, default: 48.hours
end

module ActiveStorageBlobServiceUrlForDirectUploadExpiry
  def service_url_for_direct_upload(expires_in: ActiveStorage.service_urls_for_direct_uploads_expire_in)
    super
  end
end

ActiveSupport.on_load :active_storage_blob do
  prepend ActiveStorageBlobServiceUrlForDirectUploadExpiry
end
```

A long-lived presigned PUT URL is a real (if small) exposure: anyone holding it can write that one key until it expires. I decided a working upload beats a 5-minute window, and I gate the direct-upload endpoint behind authentication so those URLs are only ever issued to signed-in users.

## Two things R2 doesn't fix for you

**Abandoned blobs pile up forever.** A user opens the file picker, the direct upload completes, then they abandon the form — the row and the R2 object stay. Nothing in Rails cleans this up:

```ruby
# app/jobs/active_storage/purge_unattached_blobs_job.rb
# frozen_string_literal: true

class ActiveStorage::PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  STALE_AGE = 24.hours

  def perform
    ActiveStorage::Blob.unattached.where(created_at: ...STALE_AGE.ago).find_each(&:purge_later)
  end
end
```

Schedule it daily — with good_job:

```ruby
# config/initializers/good_job.rb
config.good_job.cron = {
  cleanup_unattached_active_storage_blobs: {
    cron: "45 3 * * *", # daily at 3:45am
    class: "ActiveStorage::PurgeUnattachedBlobsJob",
    description: "Remove abandoned direct-upload blobs"
  }
}
```

`purge_later` rather than `purge` so one slow R2 delete can't stall the sweep. Give it a generous window (24h) so you never purge a blob whose form is still open — someone with a half-filled form and a picked file is a real scenario.

**Public bucket means public files.** With `public: true` + a custom domain, anyone with the key can read the object — the URLs are unguessable, not private. For anything genuinely private, use a second bucket with no public access and serve through Rails in proxy mode with real authorization. I keep database backups in a separate private bucket (`myapp-backups`) with its own token, precisely so the Active Storage token cannot touch them — and so a mistake in my public-bucket config can never expose a dump.

That token scoping bites once, by the way: an R2 token scoped to one bucket returns `AccessDenied` against another, which reads like a credentials problem rather than a permissions one.

## Checklist

If you're setting this up today, in this order:

1. `gem "aws-sdk-s3"` — R2 uses Active Storage's plain S3 service.
2. Create the bucket. Scope an **Object Read & Write** token to it.
3. Connect a **custom domain** to the bucket — that's what makes it public, not any Rails setting.
4. `storage.yml`: `region: auto`, `public: true`, both `*_checksum_*` options. No `public_url` key.
5. Initializer: override `public_url` → custom domain, and `upload_options` → `super.except(:acl)`. Guard on the config *symbol*, never on `ActiveStorage::Blob.service`.
6. CSP `connect_src`: the **bucket-prefixed** R2 host, plus your CDN domain.
7. Bucket **CORS**: your app origins (+ `http://localhost:3000` only if you point dev at R2). Verify with an `OPTIONS` probe.
8. Extend the direct-upload URL expiry, and require sign-in on the direct-upload endpoint.
9. Schedule a daily unattached-blob purge.
10. Put "update R2 bucket CORS" in your domain-migration checklist.

Steps 3, 7 and 10 are dashboard state, not code. They are the ones that break silently, months later, with nothing in your git history to point at.
