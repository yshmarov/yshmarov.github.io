---
layout: post
title: "counter_cache - count how many children a records has"
author: Yaroslav Shmarov
description: conter_cache in Ruby on Rails the easy way
tags: ruby rails ruby-on-rails
cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7ufvyyw7hq13rg4s983o.png
thumbnail: /assets/thumbnails/counter-cache.png
---
Often you want to count how many child records a record has (`user.posts.count`, `user.comments.count`). 

Storing this data in a the database is more efficient (like `user.posts_count`, `user.comments_count`) than recalculating it each time. 

`counter_cache` gives us a way to recalculate the database field containing count of child records whenever a child record is created/deleted

### HOWTO

user.rb
```
has_many :posts
```
post.rb - add `counter_cache: true` to recalculate `posts_count` field in user table
```
belongs_to :user, counter_cache: true
```
console:
```
rails g migration add_posts_count_to_users posts_count:integer
```
migration:
```
add_column :users, :posts_count, :integer, default: 0, null: false
```
rails c - recalculate posts_count for all existing `posts` and `users`
```
User.find_each { |u| User.reset_counters(u.id, :posts) }
```