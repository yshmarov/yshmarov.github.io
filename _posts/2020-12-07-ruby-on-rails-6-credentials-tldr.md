---
layout: post
title: 'How to use Credentials in Ruby on Rails 6? TLDR'
author: Yaroslav Shmarov
tags: 
- ruby on rails
- credentials
- secrets
- tldr
thumbnail: data:image/png;base64,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
cover_image: /assets/thumbnails/how-to-use-credentials.png
description: Quickest guide to credentials and secrets for Rails 6
---

[See complete version of this article]({% post_url 2020-12-07-ruby-on-rails-6-credentials-full %}){:target="blank"}

### create credentials & edit:

```
rails credentials:edit 
EDITOR=vim rails credentials:edit
rails credentials:show
```

### `config/credentials.yml` example:

```
awss3:
  access_key_id: YOUR_CODE_FOR_S3_STORAGE
  secret_access_key: YOUR_CODE_FOR_S3_STORAGE
google_analytics: YOUR_CODE_FOR_GOOGLE_ANALYTICS
recaptcha:
  site_key: YOUR_CODE_FOR_RECAPTCHA
  secret_key: YOUR_CODE_FOR_RECAPTCHA
google_oauth2:
  client_id: YOUR_CODE_FOR_OAUTH
  client_secret: YOUR_CODE_FOR_OAUTH
development:
  github:
    client: YOUR_CODE_FOR_OAUTH
    secret: YOUR_CODE_FOR_OAUTH
  stripe:
    publishable: YOUR_STRIPE_PUBLISHABLE
    secret: YOUR_STRIPE_SECRET
production:
  github:
    client: YOUR_CODE_FOR_OAUTH
    secret: YOUR_CODE_FOR_OAUTH
  stripe:
    publishable: YOUR_STRIPE_PUBLISHABLE
    secret: YOUR_STRIPE_SECRET
facebook:
  client: YOUR_CODE_FOR_OAUTH
  secret: YOUR_CODE_FOR_OAUTH
```

### working with VIM

To enable editing press `i`

For exiting with saving press `Esc` & `:wq` & `Enter`

For exiting without saving press `Esc` & `:q!` & `Enter`

To make Ctrl+V work properly `Esc` & `:set paste` & `i` & Ctrl` + `V`

* Example of using credentials in `devise.rb`:

```
config.omniauth :github, Rails.application.credentials.dig(Rails.env.to_sym, :github, :id), Rails.application.credentials.dig(Rails.env.to_sym, :github, :secret)
```
or
```
if Rails.application.credentials[Rails.env.to_sym].present? && Rails.application.credentials[Rails.env.to_sym][:github].present?
  config.omniauth :github, Rails.application.credentials[Rails.env.to_sym][:github][:id], Rails.application.credentials[Rails.env.to_sym][:github][:secret]
end
```

### Example of using credentials in `stripe.rb`:

```
Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret)
```

### HINT: using `.dig` is safer

### find a credential

```
rails c
Rails.application.credentials.dig(:aws, :access_key_id)
Rails.application.credentials[Rails.env.to_sym][:aws][:access_key_id]
Rails.application.credentials.some_variable
Rails.application.credentials[:production][:aws][:id]
Rails.application.credentials.production[:aws][:id]
```

### See credentials changes in local git:
```
rails credentials:diff --enroll
git diff config/credentials.yml.enc
```

### Credentials for different environments

```
EDITOR=vim bin/rails credentials:edit --environment development
```

will generate

```
config/credentials/development.yml.enc
config/credentials/development.key
```

### Set `master.key` in production (heroku):

By default `master.key` is in `.gitignore`

```
heroku config:set RAILS_MASTER_KEY=123456789
heroku config:set RAILS_MASTER_KEY=`cat config/master.key`
heroku config:set RAILS_MASTER_KEY=`cat config/credentials/production.key`
```

Bonus: in config/environments/production.rb uncomment `config.require_master_key = true`

The `config/credentials.yml` file should NOT be in gitignore.

The `config/master.key` that decrypts the credentials SHOULD be in gitignore.

[my answer on stackoverflow](https://stackoverflow.com/questions/62011541/using-credentials-yml-with-heroku-on-rails-5-2/62011825#62011825){:target="blank"}
