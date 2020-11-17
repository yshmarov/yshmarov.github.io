---
layout: post
title: "Install Ruby on Rails 6 with Webpacker and Yarn on Ubuntu: TLDR"
author: Yaroslav Shmarov
tags: 
- ruby on rails 6
- installation
- ubuntu
- webpacker
- yarn
- tldr
thumbnail: https://upload.wikimedia.org/wikipedia/commons/1/16/Ruby_on_Rails-logo.png
---

Install Rails 6
Install latest version of Ruby, Rails, Postgresql, Yarn, Webpacker

```
rails -v
ruby -v
rvm list
rvm install ruby-2.7.2
rvm --default use 2.7.2
rvm uninstall 2.7.1
rvm uninstall 2.7.0
rvm uninstall 2.6.3
rvm uninstall 2.6.5
gem install rails -v 6.0.3
gem update rails
gem update --system
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install postgresql libpq-dev redis-server redis-tools yarn
ruby -v
rails -v
pg_config --version
```

Install Rails 5

#Ruby on Rails
rvm install ruby-2.7.1
rvm --default use 2.7.1
rvm uninstall 2.6.5
rvm uninstall 2.6.6
rvm uninstall 2.6.3
gem install rails -v 5.2.4.3

#Postgresql
sudo apt install postgresql libpq-dev
sudo su postgres
createuser --interactive
ubuntu
y 
exit