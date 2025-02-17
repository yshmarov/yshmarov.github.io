---
layout: post
title: "Upgrading to Avo Pro"
tags: avo
---

So the other day I purchased an Avo Pro license and needed to update my app to use it.

Here's the [official upgrade guide](https://docs.avohq.io/3.0/gem-server-authentication.html)

With the default approach, I need to have `BUNDLE_PACKAGER__DEV` when running `bundle install` to install the Avo Pro gem.

But I do not want to block other developers on the team with having to install Avo. Some will never need to edit Avo code.

Here's how I installed Avo Pro in a way that it's not required on each environment.

```ruby
# config/initializers/avo.rb
Avo.configure do |config|
  config.license_key = ENV["AVO_LICENSE_KEY"]
end
```

```ruby
# Gemfile
gem "avo", ">= 3.4.1"
gem "pundit"
group :avo, optional: true do
  source "https://packager.dev/avo-hq/" do
    gem "avo-pro"
  end
end
```

Useful commands for running Avo Pro locally:

```sh
BUNDLE_PACKAGER__DEV=foobar bundle install
BUNDLE_PACKAGER__DEV=foobar bundle update
export BUNDLE_PACKAGER__DEV=foobar
bundle config set --global https://packager.dev/avo-hq/ foobar
```

```ruby
# config/initializers/avo.rb
unless defined?(Avo::Pro)
  Rails.autoloaders.main.ignore(Rails.root.join("app/avo/cards"))
  Rails.autoloaders.main.ignore(Rails.root.join("app/avo/dashboards"))
end
```

### GithubCI

Add `BUNDLE_PACKAGER__DEV` key to Github and update the CI setup scripts to use it.

```yml
env:
  RAILS_ENV: test
  RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
  DATABASE_URL: "postgres://rails:password@localhost:5432/rails_test"
  # ADD THIS:
  BUNDLE_PACKAGER__DEV: ${{ secrets.BUNDLE_PACKAGER__DEV }}
```

### Production

Add these environment variables.

```sh
RAILS_GROUPS=avo
BUNDLE_WITH=avo
BUNDLE_PACKAGER__DEV=foobar
AVO_LICENSE_KEY=bizzbazz
```

That's it!
