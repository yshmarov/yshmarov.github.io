---
layout: post
title: Computed PostgreSQL fields in Rails
author: Yaroslav Shmarov
tags: postgresql rails
thumbnail: /assets/thumbnails/rails-logo.png
---

Transaction

```sh
# Migration
add_column :transactions, :amount_cents, :bigint, default: 0, null: false
add_column :transactions, :fee_cents, :bigint, default: 0, null: false
add_column :transactions, :total_amount_cents, :bigint, default: 0, null: false
```

You will still want to set total_amount in the model if it is important for validations.

```ruby
# models/transaction.rb
  before_validation :set_total_amount_cents, on: :create

  def set_total_amount_cents
    self.total_amount_cents = amount_cents + fee_cents
  end
```

```ruby
class ConvertTotalAmountCentsToComputedColumn < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing column
    remove_column :wallet_withdrawals, :total_amount_cents

    # Add it back as a computed column
    add_column :wallet_withdrawals, :total_amount_cents, :integer,
               as: "amount_cents + fee_cents",
               stored: true
  end

  def down
    # Remove the computed column
    remove_column :wallet_withdrawals, :total_amount_cents

    # Add it back as a regular column with default
    add_column :wallet_withdrawals, :total_amount_cents, :integer,
               null: false, default: 0
  end
end
```

```ruby
-    t.integer "total_amount_cents", default: 0, null: false
+    t.virtual "total_amount_cents", type: :integer, as: "(amount_cents + fee_cents)", stored: true
```

### Full name search

```ruby
  add_column :users, :full_name, :virtual, type: :string, as: "first_name || ' ' || coalesce(last_name, '')", stored: true
```

https://github.com/JoshSummerTop/mj-squared/commit/7246cf677d9616e5b752f9fcc8521daad1f5ace1

```ruby
class User < ApplicationRecord
  ransacker :full_name do |parent|
    # Option 1: Concatenate with a space using Arel::Nodes::InfixOperation
    Arel::Nodes::InfixOperation.new('||',
      Arel::Nodes::InfixOperation.new('||', parent.table[:first_name], ' '),
      parent.table[:last_name]
    )

    # Option 2: Use CONCAT_WS (PostgreSQL specific, generally recommended)
    # Arel.sql("CONCAT_WS(' ', users.first_name, users.last_name)")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name full_name] # Include 'full_name' in ransackable attributes
  end
end
```

```ruby
# JAMIE
ransacker :fullname, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
  Arel::Nodes::NamedFunction.new("LOWER",
    [Arel::Nodes::NamedFunction.new("concat_ws",
      [Arel::Nodes::SqlLiteral.new("' '"), parent.table[:first_name], parent.table[:last_name]])])
end

ransacker :full_name do |parent|
  Arel::Nodes::NamedFunction.new('CONCAT_WS', [
  Arel::Nodes.build_quoted(' '), parent.table[:first_name], parent.table[:last_name]
  ])
end

ransacker :full_name do |parent|
  Arel::Nodes::InfixOperation.new(
  '||',
  Arel::Nodes::InfixOperation.new(
  '||',
  parent.table[:first_name], Arel::Nodes.build_quoted(' ')
  ),
  parent.table[:last_name]
  )
end

ransacker :full_name do
  Arel.sql("CONCAT_WS(' ', users.first_name, users.last_name)")
end
```
