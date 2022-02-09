---
layout: post
title: "Gem data-migrate - an essential gem!"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails database migrations
thumbnail: /assets/thumbnails/postgresql.png
---

TLDR: use [gem data-migrate](https://github.com/ilyakatz/data-migrate){:target="blank"}.

...Sometimes when doing code changes, you need to update **data** in your production database.

A normal migration adds/removes/renames database tables/columns, adds indexes, adds database attribute validations and default values.

But what if you want to run such a command in production?

```ruby
Service.where(status: "Frozen").update_all(status: "paused")
```

**First thought**: *"I should make a backup, and enter the production console and do that"*. 

But that's always risky! Better use a **migration**. A **data migration**.

There's a gem for that! [gem data-migrate](https://github.com/ilyakatz/data-migrate){:target="blank"}

```ruby
# install the gem
bundle add data_migrate
# add a migration
rails g data_migration change_frozen_courses_to_paused
# db/data/20220125151511_change_frozen_courses_to_paused.rb
  puts "updating #{Service.where(status: "Frozen").count} -> #{Service.where(status: "paused").count}"
  Service.where(status: "Frozen").update_all(status: "paused")
  puts "done updating #{Service.where(status: "Frozen").count} -> #{Service.where(status: "paused").count}"
# run the migration and update data in the database
rake data:migrate
```

To automatically run data migrations when deploying to production, update your [Procfile]({% post_url 2021-08-10-heroku-procfile %})

```diff
# Procfile
web: bundle exec rails s
--release: rails db:migrate
++release: rails db:migrate:with_data
```

Great! One reason less to enter the production console! 🚀
