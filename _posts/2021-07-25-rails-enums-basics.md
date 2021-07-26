---
layout: post
title: "Rails enums - different approaches"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails enums
thumbnail: /assets/thumbnails/select-options.png
---

Other good posts on the topic:
* [https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html)
* [https://sipsandbits.com/2018/04/30/using-database-native-enums-with-rails/](https://sipsandbits.com/2018/04/30/using-database-native-enums-with-rails/)
* [https://naturaily.com/blog/ruby-on-rails-enum](https://naturaily.com/blog/ruby-on-rails-enum)

Enums are a Rails feature, not a Ruby feature.

* good - we get validations for available options, can fire actions and scopes 
* bad - use integer to represent strings

## Option 1

post.rb
```
  enum status: %i[draft reviewed published]
```
migration:
```
  add_column :posts, :status, :integer, default: 0
```

In this case, the order of enums is very important:

0 = draft
1 = reviewed
2 = published

If we add new values - add at the end of the array!

## Option 2 - fix integer values to specific strings (better)

post.rb
```
  enum status: { draft: 2, reviewed: 1, published: 0 }
```

## Option 3 - map enum to strings

post.rb
```
  enum status: {
    draft: "draft",
    reviewed: "reviewed",
    published: "published"
  }
```
migration:
```
  add_column :posts, :status, :string
```

## a few methods that can be called:

```
post.draft! # => true
post.draft? # => true
post.status # => "draft"

post.reviewed! # => true
post.draft?    # => false
post.status    # => "reviewed"
post.reviewed? # => true

Post.draft     # => Collection of all Posts in draft status
Post.reviewed  # => Collection of all Posts in reviewed status
Post.published # => Collection of all Posts in published status
```
