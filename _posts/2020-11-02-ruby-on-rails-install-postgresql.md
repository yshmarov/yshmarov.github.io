---
layout: post
title:  "Ruby on Rails: How to setup Postgresql? TLDR"
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

add `gem "pg"`

remove `gem "sqlite"`

# 2. console:

[SCRIPT TO INSTALL LATEST VERSION OF POSTGRESQL](https://www.postgresql.org/download/linux/ubuntu/){:target="blank"}

Install Postgresql and create a user:

```sh
sudo apt install postgresql libpq-dev
sudo su postgres
createuser --interactive
ubuntu
y 
exit
```

check version of postgresql
```sh
pg_config --version
```

To create another user with a password:

```sh
sudo su postgres
createuser --interactive --pwprompt
username
password
y
exit
```

Set default password for a postgresql user: in this case we set password `myPassword` for user `postgres`

```sh
sudo -u postgres psql
ALTER USER postgres PASSWORD 'myPassword';
\q
```

Now you can install the gem and run migrations:

```sh
bundle
rails db:create db:migrate
rails s
```

That's it 🥳 !

****

# **Relevant links**

* [install/update postgresql script](https://www.postgresql.org/download/linux/ubuntu/){:target="blank"}
* [create a postgresql user and password](https://www.a2hosting.com/kb/developer-corner/postgresql/managing-postgresql-databases-and-users-from-the-command-line){:target="blank"}
* [Install the latest version of Postgresql](https://techviewleo.com/how-to-install-postgresql-database-on-ubuntu/){:target="blank"}