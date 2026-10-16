---
layout: post
title: "Rails World 2026: The RubyGems Compact Index: What Powers Every `bundle install` (Jenny Shen)"
author: Yaroslav Shmarov
tags: rails-world conference rubygems bundler security
thumbnail: /assets/thumbnails/youtube/Z9XUvK8Sr5c.jpg
image:
  path: /assets/images/youtube/Z9XUvK8Sr5c.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: The RubyGems Compact Index: What Powers Every `bundle install` (Jenny Shen)"
youtube_id: Z9XUvK8Sr5c
---

Jenny Shen is a senior developer at Shopify and a rubygems.org maintainer. The talk explains the compact index, the small set of files Bundler reads every time it resolves your Gemfile, and two recent changes built on top of it: **dependency cooldowns** and **content-addressable gems**. Both affect every Rails app's `bundle install`.

## Key ideas

### How the compact index works

The compact index squeezes metadata for the 200,000+ gems on rubygems.org into plain text files. It serves over 50 million requests a day through three endpoints: `versions`, `info/<gem>` and `names`. Bundler only uses the first two.

When Bundler needs to resolve (no lockfile, a changed Gemfile, or missing gems):

1. It updates its local copy of `versions` (kept in your Bundler cache) using an ETag, downloading only the new bytes. Each line has a gem name, its versions and an **info checksum**.
2. For each gem it needs, it hashes its local `info` file. If that matches the checksum from `versions`, there's nothing to fetch. Otherwise it downloads the new `info` file, which lists each version's dependencies, Ruby and RubyGems requirements and checksums.

On the server side, a push or yank fires a background job that appends a line to `versions` and rewrites that gem's `info` file in an S3 bucket. The CDN serves compact index requests from the bucket and falls back to the app if something is wrong. A monthly rake task compacts the many appended lines in `versions` back into one line per gem.

### Dependency cooldowns

Takeovers of maintainer accounts are getting more common. The trigger here was the **axios** compromise on npm earlier this year, where a hijacked maintainer account published malicious versions. PyPI and npm tooling quickly added cooldowns: don't install a version until it has been public for N days, so scanners have time to catch it and get it yanked.

Bundler needed publish timestamps, and the `info` files didn't have them. The compact index format allows extra requirement fields, so they added a created-at value. The hard part was regenerating 200,000 files in S3. They did a **blue-green migration**: write every push and yank to both the old index and a new `v2` directory, backfill everything, then point the CDN at the new directory, with an easy way back if anything broke.

Bundler (the feature was added by Hiroshi Shibata) supports it in three places:

```ruby
# Gemfile
source "https://rubygems.org", cooldown: 7
```

```bash
bundle config set cooldown 7
bundle install --cooldown 7
bundle update rack --cooldown 0 # urgent security fix
```

### Content-addressable gems

Jenny's numbers: more than **70% of `bundle install` time** goes to compiling native extensions. Precompiled gems like Nokogiri avoid that, but each platform gem bundles a binary for every supported Ruby minor version (ABI), since binaries aren't compatible across them. You only ever need one, and maintainers have to ship loader code to pick the right binary. You also can't add support for a new Ruby to an existing version.

The fix is gems built for a **single Ruby ABI**, named with a suffix taken from the first characters of the file's checksum instead of a platform, so several single-ABI builds of the same version don't collide. The platform moves into the requirements, and the Ruby requirement is pinned to one ABI. Bundler prefers these builds and records them in a new lockfile section. Pushing single-ABI builds for the precompiled gems of a new Rails app cut the bundle download size by about 20%. Support for rake-compiler is in a PR.

If you maintain a gem with native extensions that isn't precompiled, Shopify's **cibuildgem** generates a GitHub workflow that precompiles per platform and pushes to rubygems.org.

### What's next

Ideas include security advisory data in the index, so Bundler can warn about vulnerable versions, and Ruby engine requirements so precompiled binaries aren't installed on TruffleRuby by mistake.

## My takeaways

- Turn on a cooldown. `cooldown: 7` on your rubygems source is a one-line supply-chain defense.
- Keep `--cooldown 0` in mind for the day a security release lands and you can't wait a week.
- If you maintain a native gem, precompile it. cibuildgem reduces it to one generated workflow file.
- Try the RubyGems and Bundler betas so bugs show up before the stable release.

Watch the full talk: [The RubyGems Compact Index: What Powers Every `bundle install`](https://www.youtube.com/watch?v=Z9XUvK8Sr5c)
