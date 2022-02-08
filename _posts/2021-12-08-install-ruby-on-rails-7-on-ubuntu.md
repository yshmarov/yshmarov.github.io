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

Install the latest version of 
[Ruby 3](https://www.ruby-lang.org/en/downloads/releases/),
[Rails 7](https://rubyonrails.org/), and Postgresql

```sh
rvm list
rvm get head
rvm install ruby-3.1.0
rvm --default use 3.1.0

gem install rails -v 7.0.1

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

Create app:
```sh
rails help
rails new askdemos -j=importmap -c=tailwind -d=postgresql
rails new askdemos -j=importmap -c=bootstrap -d=postgresql
```

To start the app, don't use `rails c` any more. You can use `./bin/dev` to start it via `Procfile.dev`

In you are using Cloud9, you might want to do this:
```diff
# Procfile.dev
--web: bin/rails server -p 3000
++web: bin/rails server -p 8080
css: bin/rails tailwindcss:watch
```

BTW, if you get errors running `./bin/dev`, try running `gem install foreman`.

Next Step - [install Postgresql]({% post_url 2020-11-02-ruby-on-rails-install-postgresql %})

****

Bonus: using Rails main in Gemfile

```ruby
gem 'rails', git: 'https://github.com/rails/rails.git'
# or
# gem 'rails', github: 'rails/rails'
```
