Deploy on Render


https://render.com/

### 1. Database setup

Create a new Postgresql database on Render [link](https://dashboard.render.com/new/database)

Copy "Internal Connection String"

Locally, add "Internal Connection String" to credentials `bin/rails credentials:edit`:

```ruby
# config/credentials.yml
database_url: postgres://corsego_user:Xb5oh0YqqJRNxlm9E1tVvSCVyDJBPJLO@dpg-c9c1qg7ho1kveddkmrfg-a/corsego
```

Update the production database URL:

```ruby
# config/database.yml
production:
  <<: *default
  # url: <%= ENV["DATABASE_URL"] %>
  url: <%= Rails.application.credentials.database_url %>
```

Don't forget to commit your changes ;)

### 2. Create new Web Sevice

[Create new Web Sevice](https://dashboard.render.com/select-repo?type=web)
Select repo


# Terminal
chmod +x bin/render-build.sh
bundle lock --add-platform x86_64-linux




# render.yaml
databases:
  - name: exampledb
    databaseName: exampledb
    user: exampleuser
    plan: free

services:
  - type: web
    name: example
    plan: free
    env: ruby
    buildCommand: "./bin/render-build.sh"
    startCommand: "bundle exec puma -C config/puma.rb"
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: exampledb
          property: connectionString
      - key: RAILS_MASTER_KEY
        sync: false
      - key: RAILS_SERVE_STATIC_FILES
        value: true


# bin/render-build.sh
#!/usr/bin/env bash
set -o errexit
bundle install -j $(nproc)
bin/rails db:migrate
bin/rails assets:precompile

