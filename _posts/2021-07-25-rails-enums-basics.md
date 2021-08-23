---
layout: post
title: "Rails enums - different approaches"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails enums
thumbnail: /assets/thumbnails/select-options.png
---

Other good posts on the topic:

* [https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html){:target="blank"}
* [https://sipsandbits.com/2018/04/30/using-database-native-enums-with-rails/](https://sipsandbits.com/2018/04/30/using-database-native-enums-with-rails/){:target="blank"}
* [https://naturaily.com/blog/ruby-on-rails-enum](https://naturaily.com/blog/ruby-on-rails-enum){:target="blank"}

Enums are a Rails feature, not a Ruby feature.

* good - we get validations for available options, can fire actions and scopes 
* bad - not so cool to use integer to represent strings

## Option 1

post.rb

```ruby
  enum status: %i[draft reviewed published]
```

migration:

```ruby
  add_column :posts, :status, :integer, default: 0
```

### inclusion validation works automatically with enums!

```
  # this is automatic!!!
  validates :status, inclusion: { in: Post.statuses.keys }
```

In this case, the order of enums is very important:

0 = draft
1 = reviewed
2 = published

If we add new values - add at the end of the array!

### to get keys/values

```
Post.statuses.keys
=> ["draft", "published"] 
Post.statuses.values
=> [0, 1] 
```

### to select an enum in a form

```
# basic
<%= form.select :status, Post.statuses.keys %>
# advanced
<%= form.select :status, options_for_select(Post.statuses.keys, { selected: @post.status || Post.new.status }), include_blank: true %>
```

## Option 2 - fix integer values to specific strings (better)

post.rb

```ruby
  enum status: { draft: 2, reviewed: 1, published: 0 }
```

## Option 3 - map enum to strings (the best)

post.rb

```ruby
  enum status: {
    draft: "draft",
    reviewed: "reviewed",
    published: "published"
  }
```

migration:

```ruby
  add_column :posts, :status, :string
```

## Bonus: setting default values

instead setting defaults on database level like

```ruby
  add_column :posts, :status, :string, default: 'draft'
  add_column :posts, :category, :string, default: 'Rails'
```

you can better do it in the model

```ruby
  enum status: %i[draft reviewed published], _default: 'draft'
  enum category: { rails: 'Rails', ruby: 'Ruby' }, _default: 'Rails'
```

to get the default value

```
Post.new.status # => "draft"
```

## a few methods that can be called when using enums:

```ruby
post.draft! # => true
post.draft? # => true
post.status # => "draft"

post.reviewed! # => true
post.draft?    # => false
post.status    # => "reviewed"
post.reviewed? # => true

Post.draft     # => Collection of all Posts in draft status
Post.not_draft     # => Collection of all Posts NOT in draft status
Post.reviewed  # => Collection of all Posts in reviewed status
Post.published # => Collection of all Posts in published status
```
