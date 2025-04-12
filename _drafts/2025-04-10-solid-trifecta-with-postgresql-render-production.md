---
layout: post
title: "Use Solid Trifecta with one Postgresql database"
author: Yaroslav Shmarov
tags: rails solid_queue solid_cache solid_cable
thumbnail: /assets/thumbnails/rails-logo.png
---

I love [gem good_job](https://blog.corsego.com/background-jobs-good-job) for processing jobs in Postgresql. No need for Redis as a dependency!

However now we have [Solid Queue](https://github.com/rails/solid_queue), [Solid Cache](https://github.com/rails/solid_cache), Solid Cable present by default in a new Rails app. They are tailored by default to work with SQLite. Not Postgresql.

You don't want to create 4 Postgres databases in production!

```sh
myapp % rails db:create
Created database 'myapp_development'
Created database 'myapp_development_cache'
Created database 'myapp_development_queue'
Created database 'myapp_development_cable'
Created database 'myapp_test'
```

### 1. Use Solid Queue & Solid Cache in primary (Postgres) database

First, ensure Solid tools are correctly installed

```sh
bin/rails solid_cache:install
bin/rails solid_cable:install
bin/rails solid_queue:install
```

We don't want separate schemas for each solid tool. Copy them as migrations to the main database

```sh
rails g migration AddSolidCable
rails g migration AddSolidCache
rails g migration AddSolidQueue
```

Remove solid databases from the condig file:

```diff
# config/database.yml
-  cache:
-    <<: *primary_production
-    database: moneygun_production_cache
-    migrations_paths: db/cache_migrate
-  queue:
-    <<: *primary_production
-    database: moneygun_production_queue
-    migrations_paths: db/queue_migrate
-  cable:
-    <<: *primary_production
-    database: moneygun_production_cable
-    migrations_paths: db/cable_migrate
```

And use the primary database for cable, cache, queue

```diff
# config/cable.yml
-    writing: cable
+    writing: primary

# or
-  connects_to:
-    database:
-      writing: primary
```

```diff
# config/cache.yml
-    writing: cache
+    writing: primary
```

Configure solid_queue in development

```diff
# config/environments/development.rb
-  config.active_job.queue_adapter = :inline
+  config.active_job.queue_adapter = :solid_queue
# we are not using a separate database
-  config.solid_queue.connects_to = { database: { writing: :queue } }
```

and in production. Do not clutter the production logs with solid_queue

```diff
# config/environments/production.rb
-  config.solid_queue.connects_to = { database: { writing: :queue } }
+  config.solid_queue.silence_polling = true

# optional
config.cache_store = :solid_cache_store
```

Run solid queue in the same process as the web app via Puma:

```diff
# config/puma.rb
- plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
+ plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"] || Rails.env.development?
```

OR run SolidQueue locally:

```diff
# Procfile.dev
+ worker: bin/rails solid_queue:start
```

### 2. Trigger a job

```sh
rails g job HelloWorld
rails c
HelloWorldJob.set(wait: 1.week).perform_later
```

### 3. View the triggered job in Mission Control dashboard

```sh
bundle add mission_control-jobs
```

```ruby
# config/application.rb
  config.mission_control.jobs.http_basic_auth_enabled = false
```

```ruby
# config/routes.rb
  mount MissionControl::Jobs::Engine, at: "/jobs"
```

### 4. Render blueprint

No need for separate worker process?!

```yml
# render.yaml

# https://render.com/docs/deploy-rails-sidekiq
# https://render.com/docs/deploy-rails#use-renderyaml-to-deploy

databases:
  - name: mysite
    region: frankfurt
    ipAllowList: [] # only allow internal connections
    plan: free
    # plan: basic-256mb

services:
  - type: web
    name: mysite
    runtime: ruby
    plan: free
    # plan: starter
    region: frankfurt
    # buildCommand: "./bin/render-build.sh"
    buildCommand: bundle install && bundle exec rails assets:precompile && bundle exec rails assets:clean && bundle exec rails db:migrate
    # preDeployCommand: "bundle exec rails db:migrate" # preDeployCommand only available on paid instance types
    startCommand: bundle exec rails server
    # startCommand: ./bin/rails server
    healthCheckPath: "/up"
    envVars:
      - key: RAILS_MASTER_KEY
        sync: false
      - key: WEB_CONCURRENCY
        value: 2
      - key: DATABASE_URL
        fromDatabase:
          name: mysite
          property: connectionString
      - key: SOLID_QUEUE_IN_PUMA
        value: "true"
  # - type: worker
  #   name: postgres-worker
  #   runtime: ruby
  #   plan: starter
  #   buildCommand: bundle install
  #   startCommand: bundle exec rake solid_queue:start
  #   startCommand: bin/rails solid_queue:start
  #   envVars:
  #     - key: DATABASE_URL
  #       fromDatabase:
  #         name: postgres
  #         property: connectionString
  #     - key: RAILS_MASTER_KEY
  #       sync: false
```

Resources:

- https://github.com/rails/solid_queue?tab=readme-ov-file#single-database-configuration
- https://andyatkinson.com/solid-queue-mission-control-rails-postgresql
- https://andyatkinson.com/solid-cache-rails-postgresql

---

### What Render is missing:

- Buildpacks (jemallock)
- referral codes
- Disks: store sqlite dbs? store files?
- get some credits to play around?
- only 1 free tier database?

### ?

TARGET_DB=postgres bin/rails db:setup

### Recurring jobs

bin/jobs --recurring_schedule_file=config/schedule.yml

### Caching

Rails.cache.fetch("foo-123"){ SecureRandom.hex }
Rails.cache.fetch("foo-123")
Rails.cache.fetch("foo-123456",expires_in: 10.seconds){ "bar" }

bin/rails dev:cache
