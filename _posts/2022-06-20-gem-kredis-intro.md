---
layout: post
title: "Gem Kredis #1 - access Redis via ActiveRecord"
author: Yaroslav Shmarov
tags: ruby-on-rails redis kredis
thumbnail: /assets/thumbnails/redis.png
---

Normally we use a relational database like `postgresql` or `mysql` in a Rails app.

We also would normally add `Redis` as a database for background job processors like **Sidekiq**.

As of Rails 7, we **require** `Redis` to be able to process `Turbo Broadcasts`.

Also, now when we start a new Rails 7 app, a new
[`gem 'kredis'`](https://github.com/rails/kredis)
is recommended in the Gemfile.

The gem allows us to access Redis via ActiveRecord and easily write/read data on Redis.

But... **when** and **what** should we store in Redis?

### Redis VS Postgres

Postgres - a normal relational database stores **data on disc** and expects most of the data not to be frequently read. Long-term data storage.

Redis - an **in-memory** database - data is faster accessible. Short-term data storage.

Redis is good to use for data that should be easily retrievable and losable.

To try it out, first [install the gem](https://github.com/rails/kredis#installation)

```ruby
preferences = Kredis.hash('preferences')
# <Kredis::Types::Hash:0x0000000107514368
preferences.keys
# []
preferences.update(view: 'card')
# 1
preferences.keys
# ["view"]
preferences['view']
# "card"
preferences.delete('view')
# 1
preferences.keys
# []

s = Kredis.string "mystr"
s.value = "abc"
s.value
# "abc"

i = Kredis.integer "myint"
i.value = 5
i.value
# 5
```

And **importantly**, you can "associate" a redis column with an ActiveRecord object:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  kredis_hash :preferences
end
```

```ruby
User.first.preferences.update(color_mode: "dark")
User.first.preferences
# => [color_mode: "dark"]
User.first.preferences[:color_mode]
# => dark
```

This opens us a to a wide range of opportunities.

Here are some example usecases that come to my mind:

- ✅ `n` recently visited pages `kredis_unique_list` (array)
- ✅ `n` latest search results `kredis_unique_list` (array)
- ✅ user preferences - card/table layout `kredis_hash`
- ✅ user preferences - items per page `kredis_hash`
- ✅ user preferences - light/dark mode `kredis_hash`
- ✅ "saved" search filter (url params) `kredis_string`
- ✅ maximum free page visits without login `kredis_integer`
- ✅ users online `kredis_list`
- 🤔 multistep form progress?
- 🤔 cookies preferences?
- 🤔 temporary computations?
- 🤔 API call results that can be reused between requests?
- 🤔 CACHING - sidebar counters?
- 🤔 CACHING - database rows
- 🤔 whatever you would store in the session/cookies?

### Cool projects using Kredis:

* [julianrubisch/cubism](https://github.com/julianrubisch/cubism)
* [leastbad/allfutures](https://allfutures.leastbad.com/)
* [StimulusReflex/kredis](https://docs.stimulusreflex.com/rtfm/persistence#kredis)
