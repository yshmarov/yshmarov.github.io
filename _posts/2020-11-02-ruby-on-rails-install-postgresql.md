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
thumbnail: https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Postgresql_elephant.svg/1200px-Postgresql_elephant.svg.png
---

# 1. gemfile:

add `gem "pg"``

remove `gem "sqlite"``

# 2. console:


Install Postgresql and create a user:

```
sudo apt install postgresql libpq-dev
sudo su postgres
createuser --interactive
ubuntu
y 
exit
```

To create another user with a password:

```
sudo su postgres
createuser --interactive --pwprompt
username
password
y
exit
```

Now you can install the gem and run migrations:

```
bundle
rails db:create db:migrate
rails s
```

That's it 🥳 !

****

# **Relevant links**

* [install/update postgresql script](https://www.postgresql.org/download/linux/ubuntu/){:target="blank"}
* [create a postgresql user and password](https://www.a2hosting.com/kb/developer-corner/postgresql/managing-postgresql-databases-and-users-from-the-command-line){:target="blank"}
