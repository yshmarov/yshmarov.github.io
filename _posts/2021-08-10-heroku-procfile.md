---
layout: post
title: "Procfile: automatically run migrations on Heroku deploy"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails heroku procfile
thumbnail: /assets/thumbnails/procfile-logo.png
---

## Final result: automatically run migrations right when app is deployed!

![heroku procfile](/assets/images/Procfile.png)

## The Problem

When you deploy to production, afterwards you most likely write a console command like `heroku run rails db:migrate`, right?

Well, there's the `Procfile` - a file where you list commands that should be run on deploy. Heroku automatically scans for it. 

For other platforms (not heroku) you might need a tool like [foreman](https://github.com/ddollar/foreman).

## How to use:

1. Create a file named `Procfile` in your application root folder

2. Inside `Procfile` add these lines to run migrations right when the app gets deployed:
```
web: bundle exec rails s
release: rails db:migrate
```

## Bonus: also start sidekiq on deploy

Procfile
```
web: bundle exec rails s
worker: bundle exec sidekiq -c 2
release: rails db:migrate
```
