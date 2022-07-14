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

```ruby
# app/models/post.rb
  enum status: %i[draft reviewed published]
```

```ruby
# migration
  add_column :posts, :status, :integer, default: 0
```

### inclusion validation works automatically with enums!

```ruby
# app/models/post.rb
  # this is automatic!!!
  validates :status, inclusion: { in: Post.statuses.keys }
```

In this case, the order of enums is very important:

0 = draft
1 = reviewed
2 = published

If we add new values - add at the end of the array!

### to get keys/values

```ruby
Post.statuses.keys
=> ["draft", "published"] 
Post.statuses.values
=> [0, 1] 
```

### to select an enum in a form

```ruby
# basic
<%= form.select :status, Post.statuses.keys %>
# advanced
<%= form.select :status, options_for_select(Post.statuses.keys, { selected: @post.status || Post.new.status }), include_blank: true %>
```

## Option 2 - fix integer values to specific strings (better)

```ruby
# app/models/post.rb
  enum status: { draft: 2, reviewed: 1, published: 0 }
```

## Option 3 - map enum to strings (the best)

```ruby
# app/models/post.rb
  enum status: {
    draft: "draft",
    reviewed: "reviewed",
    published: "published"
  }
```

```ruby
# migration
  add_column :posts, :status, :string
```

### Postgresql enum

[Rails 7 now supports `postgresql enum` migrations](https://github.com/rails/rails/commit/4eef348584087c81f1e32ad971baf632b0149cd4):

```ruby
# migration
class CreatePosts < ActiveRecord::Migration[7.0]
  def up
    create_enum :post_status, ["draft", "reviewed", "published"]

    create_table :posts do |t|
      t.enum :current_mood, enum_type: "post_status", default: "draft", null: false
      # t.column :status, :post_status, null: false, index: true
    end
  end

  # to drop the enum table:
  def down
    execute <<-SQL
      DROP TYPE post_status;
    SQL
  end
end
```

## Bonus: setting default values

instead of setting defaults on database level like:

```ruby
# migration
  add_column :posts, :status, :string, default: 'draft'
  add_column :posts, :category, :string, default: 'Rails'
```

you could (better) do it in the model:

```ruby
# app/models/post.rb
  enum status: %i[draft reviewed published], _default: 'draft'
  enum category: { rails: 'Rails', ruby: 'Ruby' }, _default: 'Rails'
```

to get the default value:

```
Post.new.status # => "draft"
```

## a few methods that can be called when using enums:

```ruby
Post::STATUSES[:draft] # => "draft"

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
