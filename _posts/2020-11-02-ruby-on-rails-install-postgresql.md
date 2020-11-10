---
layout: post
title:  "Ruby on Rails: Install Postgresql"
author: Yaroslav Shmarov
tags:
- ubuntu
- postgres
- pg
- postgresql
- ruby on rails
---
# 1. gemfile:

add `gem "pg"``

remove `gem "sqlite"``

# 2. console:

```
sudo apt install postgresql libpq-dev
sudo su postgres
createuser --interactive --pwprompt
username
password

bundle
rails db:create db:migrate
rails s
```

That's it 🥳 !

****

# **Relevant links**

* [install/update postgresql script](https://www.postgresql.org/download/linux/ubuntu/){:target="blank"}
* [create a postgresql user and password](https://www.a2hosting.com/kb/developer-corner/postgresql/managing-postgresql-databases-and-users-from-the-command-line){:target="blank"}
