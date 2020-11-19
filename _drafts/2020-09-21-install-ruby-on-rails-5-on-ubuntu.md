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
thumbnail: https://upload.wikimedia.org/wikipedia/commons/1/16/Ruby_on_Rails-logo.png
---

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
