---
layout: post
title: Use Sidekiq in Development and Production
author: Yaroslav Shmarov
tags: ruby rails active-job sidekiq
thumbnail: /assets/thumbnails/sidekiq-logo.png
---

**ActiveJob** is a Rails feature for background job processing.

This means that you can make tasks run **in parallel** to the `rails server` request-response cycle **in a separate process**.

There are different **adapter tools** for processing ActiveJobs.

Previously I wrote about [processing ActiveJobs with gem good_job and Postgres without Redis]({% post_url 2022-12-04-background-jobs-good-job %}).

### Jobs vs Services

This tweet was a real "paradigm shift" for me:

![sidekiq metrics dashboard](/assets/images/active-job-vs-services.png)

Since I read this post, I do not create a "`/services`" folder in my Rails apps. Instead, I put everything under "`/jobs`"

### Install Sidekiq

[Gem Sidekiq](https://github.com/sidekiq/sidekiq) might be the most popular ActiveJob adapter. It uses **Redis database** to store a que of jobs that should be performed, and their execution statuses.

```ruby
# Gemfile
# bundle add sidekiq
gem 'sidekiq'
```

Run sidekiq in a separate terminal tab, or add it to Procfile.dev

```diff
# Procfile.dev
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
+worker: bundle exec sidekiq -c 5 -q default
```

By default, ActiveJob runs within with your `rails server` in development. Enforce sidekiq for the development environment:

```ruby
# config/environments/development.rb
  config.active_job.queue_adapter = :sidekiq
```

Sidekiq provides a dashboard to view the execution statuses of all your jobs.

![sidekiq metrics dashboard](/assets/images/sidekiq-dashboard-example.png)

Enable the dashboard in routes:

```ruby
# config/routes.rb
mount Sidekiq::Web => '/sidekiq'
```

Now you can visit http://localhost:3000/sidekiq to view the dashboard! 🥳

Enable access to the sidekiq dashboard **only for authenticated admin users**:

```ruby
# config/routes.rb
require 'sidekiq/web'
Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
```

### Deploy to production and use Sidekiq with Redis

There are 3 things you need to do:

1. Enable sidekiq for production:

```ruby
# config/environments/production.rb
  config.active_job.queue_adapter = :sidekiq
```

2. Create a worker with the run command `bundle exec sidekiq -c 5 -q default` (heroku example):

![sidekiq run command on heroku](/assets/images/sidekiq-worker-run-heroku.png)

3. Install Redis and provide the `REDIS_URL` to your worker (render example):

![provide redis url to worker on render](/assets/images/sidekiq-redis-url-render.png)

That's it! 🎬
