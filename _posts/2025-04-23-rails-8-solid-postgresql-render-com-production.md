---
layout: post
title: "Deploy Rails 8 on Render.com"
author: Yaroslav Shmarov
tags: rails solid_queue solid_cache solid_cable
thumbnail: /assets/thumbnails/rails-logo.png
---

I've been using Heroku since 2015 - that's 10 years of experience. However, over the years, new Platform as a Service (PaaS) providers have emerged that offer better value and pricing than Heroku. Most notably - [Render.com](https://render.com).

### SupeRails on Render

I've been hosting [SupeRails.com](https://superails.com) on Render for 2 years now, and the experience has been excellent.

The setup is straightforward:

- A web server
- A PostgreSQL database
- A worker running ActiveJob with [good_job](https://blog.corsego.com/background-jobs-good-job) on PostgreSQL

![Render setup](/assets/render/render-sr-1-setup.png)

It costs me $21/month, which perfectly covers my current workload.

![Render billing](/assets/render/render-sr-2-billing.png)

I'm not using Docker for deployment, so I don't have access to buildpacks like `jemalloc` or `headless chrome`.

It would be great if Render could support buildpacks like Heroku does:

![Heroku buildpacks](/assets/render/render-heroku-buildpacks.png)

### Rails 8 "No PaaS"

![No PaaS](/assets/render/render-nopaas.png)

In his 2024 RailsWorld keynote, DHH introduced Kamal 2 - a deployment solution for running Rails apps on your own hardware instead of in the cloud. While this sounds interesting, in practice you'd still be renting hardware from providers like Hetzner. You'd also be responsible for managing servers, SSL certificates, multiple SQLite databases, and backups. This means more DevOps work and a new learning curve.

For me, ease of production deployment and maintenance has always been crucial. I'd rather pay a few extra dollars than spend time on DevOps tasks.

> A problem that can be solved with money is not really a problem

![Kamal maybe](/assets/render/render-kamal-maybe.png)

### Rails 8 Solid Cache, Queue, Cable

By default, Rails 8 configures Solid to work with SQLite. If you want to use it with PostgreSQL on Render, check out my tutorial: [Solid Trifecta with PostgreSQL]({% post_url 2025-04-22-solid-trifecta-with-postgresql %})

One of the coolest features of Solid Queue is its Puma adapter. When you set `ENV["SOLID_QUEUE_IN_PUMA"]` to `true`, jobs will run in the same process as your web app, reducing the resources needed!

### Deploy to Render

While you can manually create and connect services (Web, Worker, Database, Redis, etc.), my preferred deployment method on Render is using a `render.yaml` [blueprint](https://dashboard.render.com/blueprints). This allows you to manage your entire Render deployment through a single file that's committed to Git!

Here's my [`render.yaml`](https://github.com/yshmarov/moneygun/blob/main/render.yaml) for deploying my Rails 8 Boilerplate app:

```yml
# render.yaml
databases:
  - name: moneygun-db
    region: frankfurt
    ipAllowList: [] # only allow internal connections
    plan: free
    # plan: basic-256mb
    # diskSizeGB: 1

services:
  - type: web
    name: moneygun-web
    runtime: ruby
    plan: free
    # plan: starter
    region: frankfurt
    buildCommand: bundle install && bundle exec rails assets:precompile && bundle exec rails assets:clean && bundle exec rails db:migrate
    # preDeployCommand: "bundle exec rails db:migrate" # preDeployCommand only available on paid instance types
    #  startCommand: bundle exec rails server
    startCommand: ./bin/rails server
    healthCheckPath: "/up"
    envVars:
      - key: SENSIBLE_DEFAULTS
        value: enabled
      - key: RAILS_ENV
        value: production
      - key: RAILS_MASTER_KEY
        sync: false
      - key: WEB_CONCURRENCY
        value: 2
      - key: SOLID_QUEUE_IN_PUMA
        value: "true"
      - key: DATABASE_URL
        fromDatabase:
          name: moneygun-db
          property: connectionString
```

If you have a `render.yaml` file in your GitHub repository, you can add a one-click deploy button to your README!

![Deploy button](/assets/render/render-deploy-button.png)

Example script:

```
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/yshmarov/moneygun)
```

More Render blueprint examples:

- [Blueprint for Advanced Rails app (Forem)](https://github.com/render-examples/forem/blob/master/render.yaml)
- [Sidekiq](https://render.com/docs/deploy-rails-sidekiq)

### Render Pricing

If you're just getting started, the free plan will be sufficient to deploy an app to production.

You get a free web server:

![Free web](/assets/render/render-free-web.png)

And **one** free database:

![Free database](/assets/render/render-free-db.png)

However, the free plan has limitations, and you won't have access to features like `rails console`.

The basic plan ($6 + $7 = $13) would be enough to deploy a fully-featured web app with a database and Solid Queue worker to production.

🤠 That's it! Time to move your apps from Heroku to Render!

---

P.S. A big thank you to [Render.com](https://render.com) for sponsoring this article! It gave me the opportunity to dive deeper into deploying Solid with PostgreSQL and explore `render.yaml`.
