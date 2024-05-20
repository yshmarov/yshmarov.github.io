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

6. Troubleshooting

```shell
# log in with user "root" and input password on next step
mysql -u root -p
# view all mysql users
SELECT user,authentication_string,plugin,host FROM mysql.user;

# start/stop/restart mysql
brew services start mysql
brew services stop mysql
brew services restart mysql

# find socket for connecting to mysql for database.yml
mysqladmin variables | grep socket

# socket: /var/run/mysqld/mysqld.sock
# socket: /tmp/mysqld.sock
socket: /tmp/mysql.sock
```