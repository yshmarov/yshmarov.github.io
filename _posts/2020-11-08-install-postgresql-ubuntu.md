---
layout: post
title:  "Ruby on Rails: Install Postgresql on Ubuntu: TLDR"
author: Yaroslav Shmarov
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

# That's it 🥳 !

Useful links:

* [install/update postgresql script](https://www.postgresql.org/download/linux/ubuntu/)

* [create a postgresql user and password](https://www.a2hosting.com/kb/developer-corner/postgresql/managing-postgresql-databases-and-users-from-the-command-line)

{% highlight ruby %}
def foo
  puts 'foo'
end
{% endhighlight %} 

[See our other post]({% post_url 2020-11-07-welcome-to-jekyll %})