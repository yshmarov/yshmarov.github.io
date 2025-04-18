---
layout: post
title: "Use Solid Trifecta with one Postgresql database"
author: Yaroslav Shmarov
tags: rails solid_queue solid_cache solid_cable
thumbnail: /assets/thumbnails/rails-logo.png
---

I love [gem good_job](https://blog.corsego.com/background-jobs-good-job) for processing jobs in Postgresql. No need for Redis as a dependency!

However as of Rails 8 we have [Solid Queue](https://github.com/rails/solid_queue), [Solid Cache](https://github.com/rails/solid_cache), [Solid Cable](https://github.com/rails/solid_cable) present by default in a new Rails app.

These tools are configured by default to work with SQLite. Not Postgresql.

Even if you generate a new Rails app via `rails new myapp -d=postgresql`.

```sh
myapp % rails db:create
Created database 'myapp_development'
Created database 'myapp_development_cache'
Created database 'myapp_development_queue'
Created database 'myapp_development_cable'
Created database 'myapp_test'
```

You most likely don't want to pay for 4 Postgres databases in production!

### 1. Use Solid Queue & Solid Cache in primary (Postgres) database

Docs: [Solid Queue: Single database configuration](https://github.com/rails/solid_queue?tab=readme-ov-file#single-database-configuration)

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

Other resources:

- [andyatkinson: Solid Queue](https://andyatkinson.com/solid-queue-mission-control-rails-postgresql)
- [andyatkinson: Solid Cache](https://andyatkinson.com/solid-cache-rails-postgresql)
