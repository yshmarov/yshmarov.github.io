---
layout: post
title: "Self-hosted inbound email for Rails: Postfix, Rspamd and Action Mailbox on Kamal"
author: Yaroslav Shmarov
tags: ruby-on-rails action-mailbox kamal docker security email
---

Most Rails apps that receive email use a provider: Postmark, Mailgun, SendGrid or SES. The provider runs the MX, parses the message and POSTs it to your app. This is easy, and for most apps it is the right choice.

I could not use one. In [EthicsPortal](https://ethicsportal.eu){:target="blank"}, people send whistleblowing reports by email. Every inbound provider I checked keeps the raw message for some time (one day, seven days, 28 days), and that makes the provider a subprocessor that holds the most sensitive data in the product.

So the app runs its own receive-only mail server, next to Rails, on the same Kamal host. It has been in production since October 2026. This post is the full recipe, with every config file, and the problems I hit on the way.

**What you get:**

- `anything@in.example.com` arrives on **your** server and becomes a record in Rails.
- No third party sees the message.
- Unknown addresses are refused during the SMTP conversation.
- Mail is queued (not lost) while Rails deploys or is down.
- SPF, DKIM and DMARC are checked, and the verdict goes to Rails.
- TLS with a Let's Encrypt certificate.
- Logs without sender addresses.

**What it costs:** two small containers, port 25 open on the server, and a few DNS records.

## The architecture

```text
sender's mail server ──SMTP:25──▶ mail accessory (Postfix)
                                   │ milter ⇄ rspamd accessory: SPF, DKIM, DMARC verdict
                                   │ refuses addresses not on the synced list
                                   │ queues while Rails is unreachable
                                   ▼ pipe → curl, over the Docker network
kamal-proxy ──▶ web: /rails/action_mailbox/relay/inbound_emails
                     └─▶ job: YourMailbox#process
```

Rails already has the receiving half. Action Mailbox has a **relay ingress**: an endpoint that takes a raw RFC 822 message over HTTP basic auth. It is the same endpoint the `rails action_mailbox:ingress:postfix` command uses. Postfix only needs to pipe each message into it.

In this recipe I use these names. Replace them with yours:

| Placeholder | Meaning |
|---|---|
| `app.example.com` | Your Rails app behind kamal-proxy |
| `in.example.com` | The domain people send email to |
| `mx.example.com` | The hostname of the mail server (the MX target) |
| `myapp` | Your Kamal service name |
| `ghcr.io/you/myapp-mail` | The image for the Postfix container |

## Step 1. Rails: turn on the relay ingress

The ingress needs a shared password. Generate one and put it in credentials:

```sh
ruby -rsecurerandom -e 'puts SecureRandom.alphanumeric(48)'
bin/rails credentials:edit
```

```yaml
action_mailbox:
  ingress_password: <the value>
```

`config/environments/production.rb`:

```ruby
# Without the password the ingress answers every request with a 500,
# so keep it off until the password exists.
config.action_mailbox.ingress = :relay if Rails.application.credentials.dig(:action_mailbox, :ingress_password)
```

`config/application.rb`:

```ruby
# The raw email is purged after processing (see the mailbox below).
# The inbound_emails row stays 7 days, so a redelivered message is a duplicate.
config.action_mailbox.incinerate_after = 7.days

config.x.inbound_email_domain = "in.example.com"
```

If the email content is sensitive, also give Action Mailbox its own storage service with `config.action_mailbox.storage_service = :your_encrypted_service`. The raw message then never sits next to normal uploads.

### Hide the ingress from the internet

The relay endpoint is public by default. Anyone on the internet can try passwords against it. Only the Postfix container needs to reach it, and that container is on the private Docker network. So the route answers 404 to everyone else:

`config/routes.rb`:

```ruby
mail_accessory = ->(request) { IPAddr.new(request.remote_ip).then { it.private? || it.loopback? } }

constraints(->(request) { !mail_accessory.call(request) }) do
  post "/rails/action_mailbox/relay/inbound_emails", to: proc { [404, {}, []] }
end

constraints(mail_accessory) do
  get "email_intake/recipients", to: "email_intake/recipients#index", as: :email_intake_recipients
end
```

Rails matches your app's routes before the routes of its built-in engines, so this constraint wins over Action Mailbox's own route.

kamal-proxy sets `X-Forwarded-For`, so `request.remote_ip` is the real client: the Postfix container's private IP, or a public IP for everyone else.

> **Trap: IPv6.** Over IPv6, Docker shows every client as its private gateway address. Then an internet client passes the "private IP" check. Do not publish an AAAA record for the host, and allow only IPv4 in the cloud firewall.

### The list of addresses that take email

Postfix should refuse `typo@in.example.com` while the sender is still connected. Then the sender's own server tells them about the mistake, and you never accept the message. For that, Postfix needs the list of valid addresses. Rails serves it, with the same password:

`app/controllers/email_intake/recipients_controller.rb`:

```ruby
class EmailIntake::RecipientsController < ActionController::Base
  before_action :authenticate

  def index
    render plain: Inbox.taking_email.map { "#{it.email_address.downcase}\n" }.join
  end

  private

  def authenticate
    password = Rails.application.credentials.dig(:action_mailbox, :ingress_password)
    return head :not_found if password.blank?

    http_basic_authenticate_or_request_with name: "actionmailbox", password:, realm: "Action Mailbox"
  end
end
```

It inherits from `ActionController::Base` on purpose: no session, no sign-in, no locale. Only Postfix calls it.

The model behind it. Each inbox has a random token, and its address is `<token>@in.example.com`:

```ruby
class Inbox < ApplicationRecord
  scope :taking_email, -> { where(email_enabled: true) }

  def email_address
    "#{token}@#{Rails.application.config.x.inbound_email_domain}"
  end

  # nil unless the address is on our domain and the local part is a token.
  def self.for_email_address(address)
    local_part, domain = address.to_s.strip.split("@", 2)
    find_by(token: local_part.to_s.downcase) if domain&.casecmp?(Rails.application.config.x.inbound_email_domain)
  end
end
```

Use a random token, not the customer's name. Then nobody can guess the addresses of other customers.

## Step 2. The mailbox

`app/mailboxes/application_mailbox.rb`:

```ruby
class ApplicationMailbox < ActionMailbox::Base
  routing all: "inbox"
end
```

`app/mailboxes/inbox_mailbox.rb`:

```ruby
# Mail that can't be processed is dropped, never bounced. A bounce goes to the
# From address, and spam forges it: you would send mail to innocent people.
class InboxMailbox < ApplicationMailbox
  AUTOMATED_PRECEDENCES = %w[bulk junk list auto_reply].freeze

  before_processing :drop_automated_mail, :drop_unknown_inbox
  after_processing :purge_raw_email

  def process
    inbox.messages.create!(
      subject: clean(mail.subject).squish.truncate(200),
      body: body_text,
      sender_email: sender_address,
      dmarc_result: dmarc_result
    )
  end

  private

  def inbox
    @inbox ||= Inbox.for_email_address(envelope_recipient)
  end

  # Postfix writes the envelope recipient here. To and Cc are written by the
  # sender: with Bcc, the To header names a different inbox.
  def envelope_recipient
    Array(mail.header[:x_original_to]).first.to_s
  end

  def drop_automated_mail
    drop("automated") if automated?
  end

  def drop_unknown_inbox
    drop("unknown inbox") unless inbox&.email_enabled?
  end

  def drop(reason)
    Rails.logger.info("[Inbound] Dropped #{inbound_email.id}: #{reason}")
    purge_raw_email
    bounced!
  end

  def purge_raw_email
    inbound_email.raw_email.purge_later
  end

  # Out-of-office replies, mailing lists and bounces. If you answer them,
  # you start a mail loop.
  def automated?
    auto_submitted = mail.header["Auto-Submitted"].to_s.strip.downcase
    (auto_submitted.present? && auto_submitted != "no") ||
      mail.header["Precedence"].to_s.strip.downcase.in?(AUTOMATED_PRECEDENCES) ||
      mail.header["X-Autoreply"].present? ||
      null_sender? ||
      sender_address.to_s.downcase.start_with?("mailer-daemon@") ||
      mail.delivery_status_report?
  end

  # Bounces have an empty envelope sender. Postfix writes it as Return-Path: <>.
  def null_sender?
    mail.header["Return-Path"].present? && mail.return_path.blank?
  end

  # Rspamd adds this header. Postfix deletes any copy the sender wrote,
  # so the first one is ours.
  def dmarc_result
    verdict = Array(mail.header["Authentication-Results"]).first.to_s[/\bdmarc=(\w+)/, 1]
    verdict.presence_in(%w[pass fail]) || "none"
  end

  def body_text
    text =
      if mail.text_part then mail.text_part.decoded
      elsif mail.html_part then ActionText::Content.new(mail.html_part.decoded).to_plain_text
      else mail.decoded
      end
    clean(text).strip
  end

  def clean(text)
    text.to_s.dup.force_encoding(Encoding::UTF_8).scrub.delete("\u0000")
  end

  def sender_address
    address = Array(mail.from).first.to_s.strip
    address if address.match?(URI::MailTo::EMAIL_REGEXP)
  end
end
```

The important decisions in this file:

- **`bounced!`, never `bounce_with`.** `bounced!` marks the email as processed and stops. `bounce_with` sends a bounce email to the forged From address. That is called backscatter, and it gets your server on blocklists.
- **Route by the envelope recipient.** If someone sends one email to two of your inboxes, one in To and one in Bcc, each copy must go to its own inbox.
- **Purge the raw email after processing.** Your record now holds the data. The `inbound_emails` row (Message-ID and checksum) stays until incineration, so a redelivery is still detected as a duplicate. A message that fails processing keeps its raw copy, so you can run `ActionMailbox::InboundEmail.failed.find(id).route` after you fix the bug.
- **Store the text only.** Convert HTML to plain text, so nothing the sender wrote can load a remote image later. `ActionText::Content#to_plain_text` needs Action Text; without it, `Nokogiri::HTML5(html).text` works.

### If you send an automatic reply

Many apps answer an inbound email with a confirmation. Three rules:

1. **Never reply to `automated?` mail.** Out-of-office replies answer your answer, and each answer is a new message.
2. **Rate limit replies per sender.** Some auto-responders ignore RFC 3834. Three replies per sender per hour stops the loop:

   ```ruby
   key = "inbound/replies/#{Digest::SHA256.hexdigest(sender.downcase)}"
   Rails.cache.increment(key, 1, expires_in: 1.hour).to_i <= 3
   ```

3. **Do not reply when DMARC fails.** The From address is forged, and your reply would go to the person it impersonates.

Also set the reply's `Reply-To` to an address that Postfix **refuses**, for example `noreply@in.example.com`. If a person replies to your confirmation, their own mail server tells them at once that the address does not exist. Without this, the reply quotes your confirmation (maybe with a secret in it) and comes back as a new inbound message, or goes to your support mailbox.

### A daily mail budget

Anyone can email a public address. If each inbound message makes your app send email (a confirmation, a notification to your users), a flood of spam uses up your sending quota. On a free plan of a transactional email provider, the same quota also sends your sign-in links.

Count inbound messages from the database (a restart can't reset it) and stop sending after a limit. Still save the messages:

```ruby
def within_daily_mail_limit?
  Message.where(source: "email", created_at: 1.day.ago..).count <= 50
end
```

Send yourself one alert when the limit is crossed. Without the alert, nobody knows that confirmations stopped.

### Attachments

- Ignore signature parts. Apple Mail and Outlook add S/MIME signatures automatically, and they are not files the sender chose to send:

  ```ruby
  SIGNATURE_TYPES = %w[application/pkcs7-signature application/x-pkcs7-signature application/pgp-signature].freeze
  mail.attachments.reject { it.mime_type.in?(SIGNATURE_TYPES) }
  ```

- Check the real type with `Marcel::MimeType.for(StringIO.new(data), name:, declared_type:)`, not only the declared type.
- One bad attachment should not fail the whole message. Skip it, and save how many were skipped, so the reader knows something is missing.
- Look at a limited number of parts. A message with 5,000 parts will keep a worker busy for a long time.

### Testing the mailbox

Build the message the way Postfix delivers it, with `X-Original-To` and `Return-Path`:

```ruby
class InboxMailboxTest < ActionMailbox::TestCase
  test "the envelope recipient picks the inbox, not the To header" do
    other = inboxes(:two)

    assert_difference -> { inboxes(:one).messages.count }, 1 do
      deliver(envelope_to: inboxes(:one).email_address, to: other.email_address)
    end
  end

  private

  def deliver(**)
    create_inbound_email_from_source(build_mail(**).to_s).tap(&:route)
  end

  def build_mail(envelope_to:, to: envelope_to, from: "jane@example.com", return_path: "<jane@example.com>", subject: "Hi", body: "Text")
    Mail.new do
      self["Return-Path"] = return_path
      self["X-Original-To"] = envelope_to
      self.to = to
      self.from = from
      self.subject = subject
      self.message_id = "<#{SecureRandom.uuid}@example.com>"
      text_part { body body }
    end
  end
end
```

Test these cases at least: unknown inbox, disabled inbox, auto-reply, bounce (`return_path: "<>"`), DMARC fail, Bcc routing.

In development, set `config.action_mailbox.ingress = :relay` and send test emails from `/rails/conductor/action_mailbox/inbound_emails`.

## Step 3. The Postfix container

Six small files in `.docker/mail/`.

### Dockerfile

```dockerfile
FROM alpine:3.22

RUN apk add --no-cache postfix ca-certificates curl openssl sed tini acme.sh busybox-extras \
  && adduser -S -D -H -s /sbin/nologin relay \
  && mkdir -p /usr/local/etc /var/www/.well-known/acme-challenge \
  && touch /var/www/up

COPY main.cf header_checks /etc/postfix/
COPY relay sync-recipients renew-certificate entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/relay /usr/local/bin/sync-recipients /usr/local/bin/renew-certificate /usr/local/bin/entrypoint.sh \
  && postconf -M rails/unix='rails unix - n n - 2 pipe flags=ROhu user=relay argv=/usr/local/bin/relay' \
  && postfix set-permissions

EXPOSE 25 80
ENTRYPOINT ["/sbin/tini", "-g", "--", "/usr/local/bin/entrypoint.sh"]
```

The `postconf -M` line creates a transport called `rails`. It runs the `relay` script for each message, as an unprivileged user, with at most 2 processes. The flags:

- `R` adds `Return-Path` (an empty one for bounces, which the mailbox uses).
- `O` adds `X-Original-To` with the envelope recipient.
- `h` and `u` lowercase the domain and the local part.

### main.cf

```ini
# Receive-only. Nothing is delivered locally or sent on: every accepted
# message goes to Rails through the `rails` transport.
compatibility_level = 3.10
maillog_file = /dev/stdout

mydestination =
mynetworks = 127.0.0.0/8
inet_protocols = ipv4
local_recipient_maps =
alias_maps =
alias_database =
local_transport = error:local delivery is disabled
default_transport = error:this server only receives mail
relay_transport = rails
rails_destination_recipient_limit = 1

# Only listed addresses are accepted. Until the first list arrives,
# lookups fail and senders are asked to retry later.
relay_recipient_maps = lmdb:/var/spool/postfix/recipients
smtpd_relay_restrictions = reject_unauth_destination
smtpd_recipient_restrictions = reject_non_fqdn_recipient, reject_unlisted_recipient
smtpd_sender_restrictions = reject_non_fqdn_sender, reject_unknown_sender_domain
smtpd_data_restrictions = reject_unauth_pipelining
smtpd_helo_required = yes
disable_vrfy_command = yes
smtpd_etrn_restrictions = reject
smtpd_discard_ehlo_keywords = etrn
show_user_unknown_table_name = no
smtpd_banner = $myhostname ESMTP

# Delete the sender's own copies of these headers. Then the only ones
# Rails sees come from the pipe and from Rspamd.
header_checks = regexp:/etc/postfix/header_checks

# Rspamd only adds a verdict. If it is down, mail goes through unchecked.
milter_default_action = accept
milter_protocol = 6

message_size_limit = 26214400
smtpd_recipient_limit = 5
queue_minfree = 2147483648
maximal_queue_lifetime = 3d
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 5
smtpd_client_recipient_rate_limit = 10
anvil_rate_time_unit = 60s
smtpd_client_connection_count_limit = 5
default_process_limit = 20
smtpd_timeout = 60s
smtpd_hard_error_limit = 10
smtpd_junk_command_limit = 20

# Opportunistic TLS. Self-signed until Let's Encrypt issues the first certificate.
smtpd_tls_security_level = may
smtpd_tls_chain_files = /var/spool/postfix/tls/key.pem, /var/spool/postfix/tls/cert.pem
smtpd_tls_protocols = >=TLSv1.2
smtpd_tls_mandatory_protocols = >=TLSv1.2
smtpd_tls_ciphers = high
smtpd_tls_mandatory_ciphers = high
tls_high_cipherlist = ECDHE+AESGCM:ECDHE+CHACHA20
tls_preempt_cipherlist = yes
smtpd_tls_loglevel = 1

# Never send bounces. Most clouds block outbound port 25 anyway.
bounce_queue_lifetime = 0
notify_classes =
```

Notes on the values:

- `rails_destination_recipient_limit = 1`: a message to two inboxes is piped twice, once per recipient, so `X-Original-To` always has exactly one address.
- `queue_minfree = 2147483648`: Postfix stops accepting mail when less than 2 GB is free. The queue shares the disk with your database.
- `maximal_queue_lifetime = 3d`: if Rails is down for three days, the sender's server gets the failure, not you.
- The rate limits are per client IP. A botnet has many IPs, which is why the daily budget in Rails also exists.

### header_checks

```text
/^X-Original-To:/ IGNORE
/^Authentication-Results:/ IGNORE
```

Without this, a sender writes their own `X-Original-To` and chooses the inbox, or writes `Authentication-Results: dmarc=pass`. Headers added later by the pipe and by the milter do not pass through `header_checks`, so the real ones survive.

### relay: the pipe into Rails

```sh
#!/bin/sh
# Any answer but 2xx exits 75 (EX_TEMPFAIL): Postfix keeps the message and
# retries. A deploy or an outage delays a message, it never loses one.
message=$(mktemp) || exit 75
trap 'rm -f "$message"' EXIT
cat > "$message" || exit 75

# A real email has a handful of MIME parts. Thousands only exhaust the Rails
# worker that parses them, so refuse it here (69 = EX_UNAVAILABLE).
if [ "$(grep -ci '^content-type:' "$message")" -gt 100 ]; then
  echo "too many MIME parts"
  exit 69
fi

# --upload-file streams from disk; --data-binary would read it into memory.
status=$(curl --config /usr/local/etc/relay.curlrc --silent --show-error \
  --request POST --upload-file "$message" \
  --header "Content-Type: message/rfc822" --header "Expect:" \
  --output /dev/null --write-out "%{http_code}" --max-time 120) || exit 75

case "$status" in
  2??) exit 0 ;;
  *) echo "ingress answered HTTP $status"; exit 75 ;;
esac
```

This exit code is the most important design choice. Postfix keeps the message in its queue until Rails answers 2xx. During a deploy, Rails returns 502 for a few seconds, Postfix waits and retries, and nothing is lost.

### sync-recipients: the address list from Rails

```sh
#!/bin/sh
# If Rails can't be reached, the last list stays.
set -u
list=/var/spool/postfix/recipients
answer=$(mktemp)
trap 'rm -f "$answer" "$list.new" "$list.new.lmdb"' EXIT

curl --config /usr/local/etc/recipients.curlrc --silent --show-error --fail \
  --max-time 30 --output "$answer" || exit 1

# Every line must look like an address on our domain. Anything else is a bad
# answer (an error page, for example), and the current list stays.
pattern="^[0-9a-z._-]{1,64}@$(printf '%s' "$INTAKE_DOMAIN" | sed 's/\./\\./g')$"
if grep -qvE "$pattern" "$answer"; then
  echo "sync-recipients: unexpected answer, keeping the current list" >&2
  exit 1
fi

sed 's/$/ OK/' "$answer" > "$list.new"
postmap lmdb:"$list.new" && mv "$list.new.lmdb" "$list.lmdb"
```

Cron runs it every minute. The `mv` swaps the file at once, so Postfix never reads half a list.

Every minute is 1,440 requests a day to your app. If your APM counts requests against a quota, see "Problems I hit in production" below.

> **Trap: a strict sanity check.** My first pattern only allowed the characters of new addresses. Older addresses used other letters, so one old address made the whole list "invalid", and for two minutes Postfix refused **every** address. Make the pattern match everything Rails can produce, and test it against your real data.

### renew-certificate: Let's Encrypt inside the container

```sh
#!/bin/sh
# Hourly. Until renewal is due, acme.sh exits 2 without contacting anyone.
set -u
home=/var/spool/postfix/acme
tls=/var/spool/postfix/tls

acme.sh --home "$home" --issue -d "$MAIL_HOSTNAME" -w /var/www --keylength 2048 \
  --server "${ACME_SERVER:-letsencrypt}" ${ACME_OPTIONS:-}
case $? in
  0) ;;
  2) exit 0 ;;
  *) exit 1 ;;
esac

acme.sh --home "$home" --install-cert -d "$MAIL_HOSTNAME" \
  --key-file "$tls/key.pem" --fullchain-file "$tls/cert.pem" --reloadcmd "postfix reload"
```

It uses the HTTP-01 challenge: kamal-proxy forwards `http://mx.example.com/.well-known/acme-challenge/` to the container (configured in step 5). I chose this over DNS-01 on purpose. DNS-01 needs a DNS API token in the container, and a token that can edit your DNS should not live in a container that is open to the internet on port 25.

### entrypoint.sh

```sh
#!/bin/sh
set -eu

: "${MAIL_HOSTNAME:?MAIL_HOSTNAME required, the name the MX record points to}"
: "${INTAKE_DOMAIN:?INTAKE_DOMAIN required, e.g. in.example.com}"
: "${RELAY_URL:?RELAY_URL required, the Action Mailbox relay ingress URL}"
: "${RECIPIENTS_URL:?RECIPIENTS_URL required, the list of addresses that take email}"
: "${RAILS_INBOUND_EMAIL_PASSWORD:?RAILS_INBOUND_EMAIL_PASSWORD required}"

postconf -e "myhostname = $MAIL_HOSTNAME" "relay_domains = $INTAKE_DOMAIN"
if [ -n "${RSPAMD_MILTER:-}" ]; then postconf -e "smtpd_milters = inet:$RSPAMD_MILTER"; fi

# pipe(8) clears the environment, and a password on curl's command line
# shows in the process list. So curl reads it from a file only the relay
# user can read.
curlrc() {
  printf 'url = "%s"\n' "$1"
  printf 'user = "actionmailbox:%s"\n' "$RAILS_INBOUND_EMAIL_PASSWORD"
  if [ -n "${RELAY_CONNECT_TO:-}" ]; then printf 'connect-to = "%s"\n' "$RELAY_CONNECT_TO"; fi
}
curlrc "$RELAY_URL" > /usr/local/etc/relay.curlrc
curlrc "$RECIPIENTS_URL" > /usr/local/etc/recipients.curlrc
chown relay /usr/local/etc/relay.curlrc
chmod 600 /usr/local/etc/relay.curlrc /usr/local/etc/recipients.curlrc
unset RAILS_INBOUND_EMAIL_PASSWORD

# Self-signed until renew-certificate gets a real one. Both are on the
# spool volume, so a reboot keeps the issued certificate.
tls=/var/spool/postfix/tls
if [ ! -s "$tls/cert.pem" ]; then
  mkdir -p "$tls"
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=$MAIL_HOSTNAME" \
    -keyout "$tls/key.pem" -out "$tls/cert.pem" 2>/dev/null
  chmod 600 "$tls/key.pem"
fi

# For kamal-proxy: /up for its health check, and the ACME challenges.
httpd -p 80 -h /var/www -u nobody

env="INTAKE_DOMAIN=$INTAKE_DOMAIN MAIL_HOSTNAME=$MAIL_HOSTNAME ACME_SERVER=${ACME_SERVER:-letsencrypt} ACME_OPTIONS='${ACME_OPTIONS:-}'"
cat > /etc/crontabs/root <<CRON
* * * * * $env /usr/local/bin/sync-recipients
17 * * * * $env /usr/local/bin/renew-certificate
CRON
crond -l 8
/usr/local/bin/sync-recipients || echo "sync-recipients: no list yet, senders are asked to retry" >&2
(sleep 60 && /usr/local/bin/renew-certificate) &

# The spool outlives the container, and so would a stale master.pid.
rm -f /var/spool/postfix/pid/*.pid
postfix check

# Keep your own addresses and the sending server in the log. Remove every
# sender address, HELO name and Message-ID.
postfix start-fg 2>&1 | sed -u -E \
  -e 's/(orig_to|to)=<([^>]*)>/\1=[\2]/g' \
  -e 's/(helo|message-id)=<[^>]*>/\1=<redacted>/g' \
  -e 's/<[^<>]*@[^<>]*>/<redacted>/g' \
  -e 's/(orig_to|to)=\[([^]]*)\]/\1=<\2>/g'
```

Two details here:

- **`connect-to`** tells curl: "for `app.example.com:443`, connect to the `kamal-proxy` container instead". TLS and the Host header still say `app.example.com`, so kamal-proxy routes the request to your app. But the traffic stays on the Docker network and never leaves the host, and Rails sees a private IP, which is what the route constraint from step 1 checks.
- **The log filter** first protects the `to=` addresses (your own inboxes) with square brackets, removes every other `<...@...>`, and then puts the brackets back. Postfix logs are useful for debugging, but they should not become a list of everyone who wrote to you.

## Step 4. Rspamd: SPF, DKIM and DMARC, nothing else

Rspamd is a spam filter, but here I use it only as a milter that checks SPF, DKIM and DMARC and adds one `Authentication-Results` header. It does not reject anything. Rails decides what a failure means.

Many Rspamd modules send data to outside services: DNS blocklists get the sender IP, URL checks get the links in the message, fuzzy hashes go to a shared server. For private content, turn all of them off. Each file in `.docker/rspamd/local.d/`:

`actions.conf`:

```text
# Verdicts only. Nothing is rejected, greylisted or rewritten.
reject = null;
add_header = null;
rewrite_subject = null;
greylist = null;
```

`milter_headers.conf`:

```text
use = ["authentication-results"];
skip_local = false;
skip_authenticated = false;
```

`worker-proxy.inc`:

```text
# The milter Postfix talks to. It scans in the same process.
bind_socket = "*:11332";
milter = yes;
timeout = 120s;
count = 1;
allow_file_and_shm_inputs = false;
upstream "local" {
  default = yes;
  self_scan = yes;
}
```

`worker-controller.inc` and `worker-normal.inc`:

```text
enabled = false;
```

`classifier-bayes.conf` (this one has no `enabled` switch):

```text
backend = "disabled";
```

`logging.inc` (message log lines contain sender addresses):

```text
level = "error";
```

And one file with `enabled = false;` for each of these modules: `asn`, `bayes_expiry`, `dcc`, `dkim_signing`, `fuzzy_check`, `greylist`, `history_redis`, `metadata_exporter`, `neural`, `phishing`, `ratelimit`, `rbl`, `replies`, `url_redirector`.

```sh
for m in asn bayes_expiry dcc dkim_signing fuzzy_check greylist history_redis \
         metadata_exporter neural phishing ratelimit rbl replies url_redirector; do
  echo "enabled = false;" > .docker/rspamd/local.d/$m.conf
done
```

So there is **no spam scoring**. For my use case that is fine: the address list blocks random spam, and a person reads every message anyway. If you need spam scoring, you have to accept blocklist lookups or train Bayes locally.

## Step 5. Kamal accessories

`config/deploy.yml`:

```yaml
accessories:
  mail:
    image: ghcr.io/you/myapp-mail:1.0   # bump the tag whenever .docker/mail changes
    host: <%= ENV["KAMAL_HOST"] %>
    port: "25:25"
    # Plain HTTP on mx.example.com, for the Let's Encrypt challenge.
    proxy:
      host: mx.example.com
      app_port: 80
      ssl: false
      healthcheck:
        path: /up
    options:
      health-cmd: "postfix status"
      health-interval: 30s
      memory: 256m
      memory-swap: 256m
      # Postfix's master runs as root to bind port 25 and start its daemons
      # as other users. It needs nothing more than this.
      cap-drop: ALL
      cap-add: [CHOWN, DAC_OVERRIDE, FOWNER, SETUID, SETGID, NET_BIND_SERVICE, KILL]
      security-opt: no-new-privileges
    env:
      clear:
        MAIL_HOSTNAME: mx.example.com
        INTAKE_DOMAIN: in.example.com
        RELAY_URL: https://app.example.com/rails/action_mailbox/relay/inbound_emails
        RECIPIENTS_URL: https://app.example.com/email_intake/recipients
        RELAY_CONNECT_TO: app.example.com:443:kamal-proxy:443
        RSPAMD_MILTER: myapp-rspamd:11332
      secret:
        - RAILS_INBOUND_EMAIL_PASSWORD
    # The queue (mail Rails has not accepted yet) and the certificate
    # must survive a reboot.
    volumes:
      - myapp_mail_queue:/var/spool/postfix

  rspamd:
    image: rspamd/rspamd:4.2.3
    host: <%= ENV["KAMAL_HOST"] %>
    files:
      - .docker/rspamd/local.d/actions.conf:/etc/rspamd/local.d/actions.conf
      - .docker/rspamd/local.d/milter_headers.conf:/etc/rspamd/local.d/milter_headers.conf
      - .docker/rspamd/local.d/worker-proxy.inc:/etc/rspamd/local.d/worker-proxy.inc
      # ...one line per file in .docker/rspamd/local.d
```

Kamal names accessory containers `<service>-<accessory>`, so Postfix finds Rspamd at `myapp-rspamd`. Both are on the `kamal` network with your app and kamal-proxy.

`.kamal/secrets` gives the accessory the same password that Rails reads from credentials:

```sh
RAILS_INBOUND_EMAIL_PASSWORD=$(bin/rails credentials:fetch action_mailbox.ingress_password)
```

Build and push the image, then boot Rspamd first, so the milter exists when Postfix starts:

```sh
docker buildx build --platform linux/amd64 -t ghcr.io/you/myapp-mail:1.0 --push .docker/mail
bin/kamal accessory boot rspamd
bin/kamal accessory boot mail
bin/kamal accessory logs mail   # "daemon started", then within a minute "Reload successful" from acme.sh
```

## Step 6. DNS and firewall

DNS:

```text
A     mx.example.com   →  <server IPv4>
MX    in.example.com   →  10 mx.example.com
TXT   in.example.com   →  "v=spf1 -all"
```

- If you use Cloudflare, the `A` record must be **DNS only** (grey cloud). Cloudflare's proxy does not pass SMTP.
- `v=spf1 -all` says nothing sends mail from `in.example.com`. Then nobody can forge it as a sender, and your `noreply@in.example.com` reply-to address is safe.
- Set the server's **reverse DNS** (PTR) to `mx.example.com` in your hosting panel.

Firewall: allow inbound TCP 25 from anywhere, **IPv4 only**. Docker's published ports bypass `ufw`, so the firewall of your cloud provider is the real filter in front of port 25. Port 80 is already open for kamal-proxy.

You do not need outbound port 25. Many clouds (Hetzner, AWS, GCP) block it for new accounts. This server never sends mail.

## Step 7. Check it from outside

```sh
# Unknown address: refused during SMTP with 550.
swaks --server mx.example.com --to nobody@in.example.com

# The certificate is from Let's Encrypt.
openssl s_client -starttls smtp -connect mx.example.com:25 -servername mx.example.com </dev/null | grep issuer

# The ingress is invisible from the internet: 404.
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://app.example.com/rails/action_mailbox/relay/inbound_emails
```

Then send a real email from Gmail or another provider to a real inbox address, and check in the console that the record exists and `dmarc_result` is `pass`.

> **Trap: testing from the server.** If you send a test email from the same host, it arrives from the Docker gateway. Rspamd treats that as local and adds no DMARC verdict. To test the DMARC-fail path, send from the server's **public** IP, or from another machine.

## Operations

```sh
bin/kamal accessory logs mail                       # SMTP and relay log
bin/kamal accessory exec mail "postqueue -p"        # mail waiting for Rails
bin/kamal accessory exec mail "postqueue -f"        # retry it now
bin/kamal accessory exec mail "sync-recipients"     # refresh the address list now
bin/kamal accessory exec mail "postmap -s lmdb:/var/spool/postfix/recipients"   # what it accepts
bin/kamal accessory reboot mail                     # after an image change
```

- A message that Rails rejected waits in the queue as `deferred`, with the HTTP status in the log. Postfix retries it for 3 days.
- A message that failed in your mailbox raises in `ActionMailbox::RoutingJob` and goes to your error tracker. Fix the bug, then route it again from the console.
- **Kill switch:** `bin/kamal accessory stop mail`. Sending servers then queue the mail on their side and retry for days. To turn off one inbox, disable it in Rails: within a minute it leaves the list and senders get a 550.
- Add `mail` and `rspamd` to your container health check, the same way you watch `web` and `db`.
- Rspamd's image tag is pinned in `deploy.yml`. Dependabot does not watch it, so update it yourself from time to time.

## Problems I hit in production

**The same email twice makes two records.** Action Mailbox detects duplicates by a checksum of the raw message. If a sender's server sends the same message in two separate SMTP sessions, Postfix adds a different `Received` header each time, so the checksum is different. Postfix's own retries resend the stored file and **are** detected. I accepted this. Deduplicating on Message-ID alone would drop the copy for the second inbox when someone writes to two inboxes in one email.

**The list sync lags by up to a minute.** A newly enabled inbox is refused with a permanent 550 until the next sync, and a disabled one is still accepted for a minute (and then dropped by Rails). Run `sync-recipients` by hand after you change an inbox. A live lookup per recipient (Postfix `tcp_table` or a policy server) would close the gap, but it adds moving parts.

**S/MIME signatures counted as attachments.** A signed email from Apple Mail reported "1 attachment left out". See the `SIGNATURE_TYPES` filter above.

**Replies to my own confirmations came back as new messages.** The confirmation's `Reply-To` was the inbox address. A reply quoted the whole confirmation, and that became a new record. Now `Reply-To` is an address Postfix refuses.

**The address sync used up my monitoring quota.** The sync calls Rails every minute: 1,440 requests a day, about 43,000 a month. AppSignal counts each one as a request, and its free plan allows 30,000 a month. Together with another job that ran every minute, it used up the quota in under three weeks. AppSignal then locked the account, and I could not read my errors. My normal traffic was about 250 requests a day.

The endpoint only renders a list, so I tell AppSignal to ignore it:

```ruby
# config/appsignal.rb
Appsignal.configure do |config|
  config.ignore_actions << "EmailIntake::RecipientsController#index"
end
```

AppSignal then also ignores errors from this action. That is fine here: if the sync breaks, the mail container writes it to its log. With Sentry or another APM, exclude the endpoint from performance tracing in the same way. Check every other job that runs every minute too: in a small app, background jobs on a timer can make more APM requests than your real users.

## What I deliberately did not do (yet)

- **DANE.** A TLSA record pins the certificate key. If the mail volume is ever recreated, the key changes, and servers that check DANE silently stop delivering to you. The risk is bigger than the gain.
- **MTA-STS in enforce mode.** It tells Gmail and others to require a valid certificate. If the renewal ever fails, they stop delivering. Publish it in `testing` mode only after the certificate has renewed once in production, and add TLS-RPT so you get reports.
- **Spam scoring.** Explained in step 4.

## Should you build this?

Use a provider if your app receives normal email (support replies, "reply to this comment") and you are fine with a third party holding the messages for a short time. Postmark's inbound webhook plus Action Mailbox's Postmark ingress takes an hour to set up.

Build this when the content must not leave your servers, when you don't want another subprocessor in your DPA, or when you already run Kamal and want one less monthly bill. Most of the work is in the decisions above, not in the code: about 200 lines of shell and Postfix config, plus your mailbox.

Related: [Action Mailer basics]({% post_url 2023-01-01-action-mailer-basics %}).
