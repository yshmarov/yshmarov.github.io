---
layout: post
title: install and troubleshoot mysql
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails mysql mariadb
thumbnail: /assets/thumbnails/mysql.png
---

1. console
```
sudo apt-get install mysql-server mysql-client libmysqlclient-dev
```

2. gemfile
```
gem 'mysql2', '~> 0.5.2'
```

3. database.yml

```
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password: root
  socket: /var/run/mysqld/mysqld.sock

development:
  <<: *default
  database: projectname_development

test:
  <<: *default
  database: projectname_test

production:
  <<: *default
  database: projectname_production
  username: projectname
  password: <%= ENV['PROJECTNAME_DATABASE_PASSWORD'] %>
```

note that above we set a password `root` - we need it to make it work correctly

4. set mysql passwort to be `root`. [source on stackoverflow](https://stackoverflow.com/questions/41645309/mysql-error-access-denied-for-user-rootlocalhost){:target="blank"}

console
```
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
```

press `Ctrl + D` to exit

5. that's it! now you can run migrations

console
```
rails db:create
rails db:migrate
```
