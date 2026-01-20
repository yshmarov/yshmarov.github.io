---
layout: post
title: "How to use Credentials in Ruby on Rails 6? TLDR"
author: Yaroslav Shmarov
tags: ruby-on-rails credentials secrets tldr
thumbnail: /assets/thumbnails/encryption-lock.png
description: Quickest guide to credentials and secrets for Rails 6
youtube_id: nDJE8WG0auE
---

[See complete version of this article]({% post_url 2020-12-07-ruby-on-rails-6-credentials-full %}){:target="blank"}

### create credentials & edit:

```shell
rails credentials:edit
rails credentials:show

# vim
EDITOR=vim bin/rails credentials:edit

# vscode
EDITOR="code --wait" bin/rails credentials:edit
EDITOR='code --wait' rails credentials:edit --environment=development
EDITOR='code --wait' rails credentials:edit --environment=test
EDITOR='code --wait' rails credentials:edit --environment=production

# cursor
export EDITOR="/Applications/Cursor.app/Contents/MacOS/Cursor --wait"
bin/rails credentials:edit
bin/rails credentials:edit --environment=development
bin/rails credentials:edit --environment=test
bin/rails credentials:edit --environment=production
```

### see credentials diff

Create a `.gitattributes` file in your Rails root folder & add these lines:

```diff
# See https://git-scm.com/docs/gitattributes for more about git attribute files.

# Mark the database schema as having been generated.
db/schema.rb linguist-generated

# Mark any vendored files as having been vendored.
vendor/* linguist-vendored
+config/credentials/*.yml.enc diff=rails_credentials
+config/credentials.yml.enc diff=rails_credentials
```

Now you will see credentails diff!

![readable rails credentials diff](/assets/images/readable-credentials.png)

### `config/credentials.yml` example:

```yml
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

To make Ctrl+V work properly `Esc` & `:set paste` & `i` & Ctrl`+`V`

- Example of using credentials in `devise.rb`:

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
