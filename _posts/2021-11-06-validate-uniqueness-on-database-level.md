---
layout: post
title: "Validate uniqueness on the database level"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails postgresql active-record
thumbnail: /assets/thumbnails/curlybrackets.png
---

You came here to fix `Rails/UniqueValidationWithoutIndex`
![validate-uniqueness-on-db](/assets/images/validate-uniqueness-on-db.png)

```sh
rails g scaffold inbox name
rails g scaffold message inbox:references body:text
```

## 1. Validate uniqueness

```ruby
# app/models/inbox.rb
  validates :name, uniqueness: true
```

```diff
class CreateInboxes < ActiveRecord::Migration[7.0]
  def change
    create_table :inboxes do |t|
      t.string :name, null: false
++    t.string :name, null: false, index: { unique: true }

      t.timestamps
    end
++  # add_index :messages, :body, unique: true
  end
end
```

```ruby
# app/models/message.rb
  validates :body, uniqueness: { scope: :inbox_id }
```

## 2. Validate uniqueness scope

```diff
class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.references :inbox, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end
++  add_index :messages, [:body, :inbox_id], unique: true
  end
end
```
