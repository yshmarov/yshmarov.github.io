---
layout: post
title: Heroku upload local database to production
author: Yaroslav Shmarov
tags: ruby-on-rails heroku postgresql
thumbnail: /assets/thumbnails/heroku.png
---

Previously I wrote about how to [load Heroku production database in development]({% post_url 2020-11-16-ruby-on-rails-heroku-load-production-database-in-development %})

Now, before doing such a destructive operation as replacing production db with development db, it is important to start with a backup!

### 1. Back up your current production database

For it all to work, be sure you are logged into heroku via your console (`heroku login`).

```shell
# create backup
heroku pg:backups:capture --app superails
# see a list of all backups
heroku pg:backups -a superails
# download a backup from heroku, store it as latest.dump
heroku pg:backups:download --app superails
```

### 2. Generate a dump of your local database

This command will take your database named `superails_development` and generate a file named `mydb.dump`

```shell
pg_dump -Fc --no-acl --no-owner -h localhost -U postgres -d superails_development -f mydb.dump
```

### 3. Upload the generated database dump file (`mydb.dump`) to a publicly accessible cloud storage

Create a public S3 bucket, or go to bucket permissions and click the "edit" button to make it public:

![Change S3 bucket permissions](/assets/images/s3-01-make-bucket-public-edit-button.png)

Unselect "block public access":

![S3 allow public access](/assets/images/s3-02-make-bucket-publick-allow-access.png)

Upload a file (your `mydb.dump` file) and make it public:

![S3 upload public file](/assets/images/s3-03-upload-public-file.png)

Copy the public url for your `mydb.dump`:

![S3 copy url to public file](/assets/images/s3-04-url-to-public-file.png)

### 4. Replace your production db with the `mydb.dump`

With the copied URL, run a command to replace your production database with the one you are uploading:

```shell
heroku pg:backups restore 'https://corsego-public.s3.eu-central-1.amazonaws.com/mydb.dump' DATABASE -a superails-production
```

That's it! 🤠
