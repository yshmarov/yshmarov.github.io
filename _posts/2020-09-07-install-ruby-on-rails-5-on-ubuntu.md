---
layout: post
title: "Install Ruby on Rails 5 on Ubuntu: TLDR"
author: Yaroslav Shmarov
tags: 
- ruby on rails 5
- installation
- ubuntu
- webpacker
- yarn
- tldr
thumbnail: /assets/thumbnails/rails-logo.png
---

Maybe you want to install a newer version? [Install Ruby on Rails 6]({% post_url 2020-09-07-install-ruby-on-rails-6-on-ubuntu %})

* Install Ruby on Rails 5:

```
rvm install ruby-2.7.2
rvm --default use 2.7.2
rvm uninstall 2.7.1
gem install rails -v 5.2.4.3
```

* Set up Postgresql:

```
sudo apt install postgresql libpq-dev
sudo su postgres
createuser --interactive
ubuntu
y 
exit
```

Extended Tutorial on [installing Postgresql]({% post_url 2020-11-02-ruby-on-rails-install-postgresql %})
