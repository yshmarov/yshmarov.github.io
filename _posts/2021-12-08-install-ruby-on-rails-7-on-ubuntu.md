---
layout: post
title: "Install Ruby on Rails 7"
author: Yaroslav Shmarov
tags: ruby-on-rails-7, ubuntu
thumbnail: /assets/thumbnails/rails-logo.png
---

Older posts:
* [install Rails 6]({% post_url 2020-09-07-install-ruby-on-rails-6-on-ubuntu %})
* [install Rails 7]({% post_url 2020-09-07-install-ruby-on-rails-5-on-ubuntu %})

Install the latest version of Ruby 3, Rails 7, and Postgresql

```sh
rvm list
rvm get head
rvm install ruby-3.0.3
rvm --default use 3.0.3

gem install rails -v 7.0.0.rc1

gem update bundler
gem update rails
gem update --system
sudo apt update

sudo apt install postgresql libpq-dev redis-server redis-tools

ruby -v
rails -v
bundler -v
pg_config --version
```

Next Step - [install Postgresql]({% post_url 2020-11-02-ruby-on-rails-install-postgresql %})

****

Bonus: using Rails main in Gemfile

```ruby
gem 'rails', git: 'https://github.com/rails/rails.git'
# or
# gem 'rails', github: 'rails/rails'
```
