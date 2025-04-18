---
layout: post
title: "Deploy Rails 8 on Render.com"
author: Yaroslav Shmarov
tags: rails solid_queue solid_cache solid_cable
thumbnail: /assets/thumbnails/rails-logo.png
---

I've been using Heroku since 2015. 10 years. 10 years of stagnation.

Over the years new PaaS (platform as a service) have emerged that offer more value and better pricing than Heroku does. Most notably - [Render.com](https://render.com).

### SupeRails on Render

I've been hosting [SupeRails.com](https://superails.com) on Render for 2 years now, and it's been great.

The setup is simple:

- a Web server
- a Postgres database
- a Worker, running ActiveJob with [good_job](https://blog.corsego.com/background-jobs-good-job) on Postgres

![Render setup](/assets/render/render-sr-1-setup.png)

It's costing me $21/month, and it covers my small workload.

![Render billing](/assets/render/render-sr-2-billing.png)

I'm not deploying the application via Dockerfile, so I don't have buildpacks (`jemallock`, `headless chrome` enabled).

It would be great if Render could support buildpacks like Heroku does:

![Heroku buildpacks](/assets/render/render-heroku-buildpacks.png)

### Rails 8 "No PaaS"

![No PaaS](/assets/render/render-nopaas.png)

In his 2024 RailsWorld keynote, DHH introduced Kamal 2 - a way to deploy Rails apps on your own metal, rather than in the cloud. That sounds fun, however realistically you'd be still renting hardware from something like Hetzner. And you'd be in charge of everything - servers, SSL, mutliple SQLIte databases and backups. More DevOps work. And a new learning curve.

Ease of production deployment and maintanance have always been very improtant for me. I'd better pay a few dollars more, than spend time on DevOps.

> A problem that can be solved with money is not really a problem

![Kamal maybe](/assets/render/render-kamal-maybe.png)

### Rails 8 Solid Cache, Queue, Cable

By default Rails 8 has Solid configured to run with SQLite. If you want to make it work with Postgres on Render, see my tutorial here: [Solid Trifecta with Postgres]({% post_url 2025-04-22-solid-trifecta-with-postgresql %})

It's very cool that Solid Queue has a Puma adapter. If you set `ENV["SOLID_QUEUE_IN_PUMA"]` to `true`, jobs will run in the same process as your Web app. Fewer resources to spin up!

### Deploy to Render

You can manually create and connect services (Web, Worker, Database, Redis, etc), however my favourite way to deploy on Render is via a `render.yaml` [blueprint](https://dashboard.render.com/blueprints). This way you can manage all your apps Render deployment in one file that's committed to Git!

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

If you have a `render.yaml` file in your github repo source, you can add a One-click deploy button to your readme!

![Deploy button](/assets/render/render-deploy-button.png)

Example script:

```
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/yshmarov/moneygun)
```

More Render blueprint examples:

- [Blueprint for Advanced Rails app (Forem)](https://github.com/render-examples/forem/blob/master/render.yaml)
- [Sidekiq](https://render.com/docs/deploy-rails-sidekiq)

### Render pricing

If you are just getting started, the free plan will be enough to Deploy an app to production.

You get a free web server

![Free web](/assets/render/render-free-web.png)

And **one** free database

![Free database](/assets/render/render-free-db.png)

However the free plan is limited, and you won't have access to features like `rails c`

The basic plan for 6+7=13$ would be enough to deploy a fully featured Web app with a database and Solid Queue worker to production.

🤠 That's it! Time to move your apps from Heroku to Render!

---

P.S. Thanks so much to [Render.com](https://render.com) for sponsoring my works on this article! It gave me the opportunity to dig deeper, learn about how to deploy Solid with Postgres, and use `render.yaml`.
