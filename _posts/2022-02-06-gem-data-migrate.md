---
layout: post
title: "Gem data-migrate - an essential gem!"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails database migrations
thumbnail: /assets/thumbnails/postgresql.png
---

TLDR: use [gem data-migrate](https://github.com/ilyakatz/data-migrate).

...Sometimes when doing code changes, you need to update **data** in your production database.

A normal migration adds/removes/renames database tables/columns, adds indexes, adds database attribute validations and default values.

Whereas **data migration** changes what is inside your database. Examples of data being migrated:

```ruby
# random examples of console commands that can be done as data migrations
Service.where(language_id: 5).update_all(lang_name: "IT")

Group.where(status: "Frozen").each { |g| g.update(status: "paused") }

Office.all.each do |x|
  x.update_column(:payments_sum, (x.payments.map(&:amount).sum))
  x.update_column(:expences_sum, (x.expences.map(&:amount).sum))
  x.update_column(:balance, (x.payments_sum - x.expences_sum))
end

Job.where(member_id: nil).each do |j|
  j.update(workable_type: "Supplier", workable_id: j.supplier_id)
end

Course.where(s_type: ["ind", "special"]).each do |c|
  c.update(member_price: c.client_price*0.4)
end

puts "updating #{course.id}"
course.update!(company_id: course.office.company_id)
puts "done updating #{course.id} -> #{course.company_id}"
```

**First thought**: *"I should make a backup, and enter the production console and do that"*. 

But that's always risky! Better use a **migration**. A **data migration**.

There's a gem for that! [gem data-migrate](https://github.com/ilyakatz/data-migrate)

```ruby
# install the gem
bundle add data-migrate
# add a migration
rails g data_migration add_this_to_that
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
