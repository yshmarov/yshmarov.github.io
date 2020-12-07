---
layout: post
title: "How to load Heroku production database in development?"
author: Yaroslav Shmarov
tags: 
- ruby on rails
- heroku
- postgresql
thumbnail: https://res-3.cloudinary.com/crunchbase-production/image/upload/c_lpad,f_auto,q_auto:eco/v1491420676/cenlvst0fgs8ejx12n8u.png
youtube_id: qSYLJhe2nO4
---
<div style="position: relative; width: 100%; height: 0; padding-bottom: 56.25%;">
    <iframe style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;" allowfullscreen src="https://www.youtube.com/embed/{{page.youtube_id}}"></iframe>
</div>

Sometimes you want to run a copy of your **production database in development**. 

It can be really useful for debugging, or experimenting with potentially dangerous operations.

Here's how you can run your Heroku Postgresql database in development:

* 1 Create Heroku backup

```
heroku pg:backups:capture --app myappname
```

* 2 Download Heroku backup [(source)](https://devcenter.heroku.com/articles/heroku-postgres-backups){:target="blank"}

```
heroku pg:backups:download --app myappname
```

* 3 Reset local database

```
rails db:drop
rails db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=1
rails db:create
```

* 4 Populate local database from heroku download

(place development database name from database.yml)

```
pg_restore -h localhost -d myappname_development latest.dump
```

* 5 run migrations

```
rails db:migrate
```

* 6 Remove downloaded database from app repository:

```
rm latest.dump 
```

That's it! Now you have a copy of your production database running in development🥳!

****

# Troubleshooting

* [Update postgresql](https://www.postgresql.org/download/linux/ubuntu/){:target="blank"}

* Create a new postgresql user and password [(source)](https://www.a2hosting.com/kb/developer-corner/postgresql/managing-postgresql-databases-and-users-from-the-command-line){:target="blank"}

```
createuser --interactive --pwprompt
yaro
pass
```

* Specify newly created postgresql user for restoring database and restore

```
pg_restore -h localhost -U yaro -d myappname_development latest.dump
pass
```

or 

```
PGPASSWORD=pass pg_restore -h localhost -U yaro -d myappname_development latest.dump
```

or

```
set "PGPASSWORD=pass"
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U yaro -d myappname_development latest.dump
```

****

My case:
```
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U yaro -d saas_development latest.dump
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U yaro -d corsego_development latest.dump
```

Adding `latest.dump` to gitignore: 

```
echo 'latest.dump*' >> .gitignore
```
