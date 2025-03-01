---
layout: post
title: "Upgrading to Avo Pro"
tags: avo
---

So the other day I purchased an Avo Pro license and needed to update my app to use it.

First, I followed the [official upgrade guide](https://docs.avohq.io/3.0/gem-server-authentication.html).

Here's how to install Avo Pro without requiring it for all developers on the team.

```ruby
# Gemfile
gem "avo", ">= 3.4.1"
gem "pundit"
group :avo, optional: true do
  source "https://packager.dev/avo-hq/" do
    gem "avo-pro"
  end
end
group :development, :test do
  gem "dotenv"
end
```

```sh
# .env
RAILS_GROUPS=avo
BUNDLE_WITH=avo
BUNDLE_PACKAGER__DEV=foobar
```

```ruby
# config/initializers/avo.rb
Avo.configure do |config|
  config.license_key = ENV["AVO_LICENSE_KEY"]
end

unless defined?(Avo::Pro)
  Rails.autoloaders.main.ignore(Rails.root.join("app/avo/cards"))
  Rails.autoloaders.main.ignore(Rails.root.join("app/avo/dashboards"))
end
```

### Local Development

```sh
BUNDLE_PACKAGER__DEV=foobar bundle install
BUNDLE_PACKAGER__DEV=foobar bundle update
export BUNDLE_PACKAGER__DEV=foobar
# Or set globally:
bundle config set --global https://packager.dev/avo-hq/ foobar
```

### GitHub CI

```yml
env:
  RAILS_ENV: test
  RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
  DATABASE_URL: "postgres://rails:password@localhost:5432/rails_test"
  BUNDLE_PACKAGER__DEV: ${{ secrets.BUNDLE_PACKAGER__DEV }}
```

### Production Environment Variables

```sh
RAILS_GROUPS=avo
BUNDLE_WITH=avo
BUNDLE_PACKAGER__DEV=foobar
AVO_LICENSE_KEY=bizzbazz
```
