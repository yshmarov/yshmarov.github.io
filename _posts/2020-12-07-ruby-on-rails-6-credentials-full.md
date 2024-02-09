---
layout: post
title: 'How to use Credentials in Ruby on Rails 6? Full guide'
author: Yaroslav Shmarov
tags: 
- ruby on rails
- credentials
- secrets
thumbnail: /assets/thumbnails/encryption-lock.png
description: Quickest guide to credentials and secrets for Rails 6
youtube_id: nDJE8WG0auE
---

[See TLDR version of this article]({% post_url 2020-12-07-ruby-on-rails-6-credentials-tldr %}){:target="blank"}

Often when working on a Rails app, you will have to handle vulnerable data.

Most often these are API keys to services that you integrate.

Most common examples:

* Github, Google, Twitter, Facebook oAuth 
* AWS S3 
* Stripe, Braintree etc
* Sendgrid, Mailchimp etc

Here you can see a `client_id` and `client_secret` provided by Github, so that you can add **"Log in with Github"** functionality:

![1-github-credentials](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/1-github-credentials.png)

To use these keys, you could directly place them in your `devise.rb` file like
```
config.omniauth :github, "23r32t34t4rg", "regregbesgbvtegc4g43g343"
```
However this approach creates a security threat. 

For example, if your repository is ever open sourced or shared with third parties, anybody can misuse your API keys.

That can lead to your account:

* being banned (overuse quota with too many requests)
* charged (with your API keys anybody can upload too much data to your S3 account)
* you can experience a data leak (all your application attachements from S3 can be leaked)

That's why should use credentials to encrypt sensitive data. 

An **encrypted** line in `devise.rb` would look like:
```
config.omniauth :github, (Rails.application.credentials[Rails.env.to_sym][:github][:client]).to_s, (Rails.application.credentials[Rails.env.to_sym][:github][:secret]).to_s
```
So how do you make it work?

# Let's start:

When you create a Rails 6 app, under app/config you have a file named `credentials.yml.enc`:

![2-credentials-config](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/2-credentials-config.png)

If you open the `credentials.yml.enc` file, it will usually look like this:

![3-credentials-yml-open](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/3-credentials-yml-open.png)

It is encrypted and safe to share in a public repository.

To decrypt the `credentials.yml` file, the `master.key` file is used:

![4-master-key-open](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/4-master-key-open.png)

**NEVER SHARE THE MASTER KEY WITH THE PUBLIC.**

**IF YOU LOSE THE MASTER KEY, YOU WILL NOT BE ABLE TO DECRYPT YOUR CREDENTIALS**

By default, `master.key` is not included into your git commits.

To decrypt and view or edit your `credentials.yml`, 
you can run `rails credentials:edit` 
or `EDITOR=vim rails credentials:edit`.

When decripted, the `credentials.yml` file would typically looks somewhat like this:

![5-opened-credentials](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/5-opened-credentials.png)

To retrieve any data from `credentials.yml` in your rails app or in the console, you can run something like
```
rails c
Rails.application.credentials.dig(:aws, :access_key_id)
#=> sdgb89dngfm6cg8jmbdb8f9bfg6n8fnd7bd9f
Rails.application.credentials[:github][Rails.env.to_sym][:secret]
#=> 6hl65knh4l5vgm8
```
Editing the file in VIM inside a terminal can a feel tricky and unnatural. 

To edit the file, press `i`. You will see `INSERT` appear on the bottom of the file, prompting that you are currently able to edit the file:

![6-credentials-insert](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/6-credentials-insert.png)

When you're done, press `ESC`. next press `:wq` + `ENTER` to exit with saving.

![7-credentials-save](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/7-credentials-save.png)

or press `ESC` + `:q!` + `ENTER` to exit without saving.

![8-credentials-no-save](assets/2020-12-07-ruby-on-rails-6-credentials-quick-guide/8-credentials-no-save.png)

**To set your master key in production (heroku example):**
```
heroku config:set RAILS_MASTER_KEY=YOURMASTERKEY
```
or
```
heroku config:set RAILS_MASTER_KEY=`cat config/master.key`
```

That's it :)
