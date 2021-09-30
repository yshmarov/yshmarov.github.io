---
layout: post
title: "Install and use ActiveAdmin in 13 steps"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails active-admin
thumbnail: /assets/thumbnails/admin.png
---

### 1. Create a few models

console
```sh
rails g scaffold MenuCategory name
rails g scaffold MenuItem menu_category:references name price:integer active:boolean
rails db:migrate
```

config/seeds.rb
```ruby
3.times do
  menu_category = MenuCategory.create(name: SecureRandom.hex)
	rand(1..3).times do
    menu_item = MenuItem.create(name: SecureRandom.hex, 
			menu_category: menu_category,
			price: rand(10..100))
	end
end
```

console
```sh
rails db:seed
```

### 2. Install Devise (no User model needed)

console
```sh
bundle add devise
rails generate devise:install
```

### 3. Install ActiveAdmin

[Official docs](https://activeadmin.info/documentation.html)

console
```sh
bundle add activeadmin
rails generate active_admin:install --use_webpacker
# rails generate active_admin:install
rails db:migrate db:seed
```

This will:
* add migration for admin_user
* add seeds AdminUser
* add routes for Active admin
* add app/admin folder
* adds ActiveAdminComments for internal notes

Now you login to `localhost:3000/admin` with:
login: `admin@example.com`
password: `password`

### 4. Create CRUD views for resources in ActiveAdmin

```sh
rails generate active_admin:resource MenuCategory
rails generate active_admin:resource MenuItem
```

### 5. Add Strong Params for creating/editing records in ActiveAdmin

app/admin/menu_items.rb
```ruby
  permit_params :name, :price, :menu_category_id
```

### 6. Customize Index Search

app/admin/menu_items.rb
```ruby
  filter :name
  filter :menu_category
  filter :menu_category_name, as: :string
  filter :created_at
  filter :active
  filter :price
```

### 7. Add Scopes

app/models/menu_item.rb
```ruby
  def has_price
    price.present?
  end

  scope :has_price, -> { where.not(price: nil) }
  scope :active, -> { where(active: true) }
```

app/admin/menu_items.rb
```ruby
  scope :has_price
  scope :active
```

### 8. Customize Index View

app/admin/menu_items.rb
```ruby
  index do
    selectable_column
    id_column
    column :name
    column :price
    column :created_at
    column :active
    actions
  end
```

### 9. Customize Show View

app/admin/menu_items.rb
```ruby
  show do
    attributes_table do
      row :id
      row :name
      row :has_price
      row :menu_category
      row :price
      row :created_at
    end
    active_admin_comments
  end
```

### 10. Customize Form

app/admin/menu_items.rb
```ruby
  form do |f|
    f.inputs :name, :price, :menu_category
    # input multiple (good for many-to-many relationship)
    # f.inputs 'Menu Categories' do
    #   f.input :menu_categories, as: :check_boxes
    # end
    actions
  end
```

### 11. Add custom button actions

app/models/menu_item.rb
```ruby
  def switch_active!
    toggle!(:active)
  end
```

app/admin/menu_items.rb
```ruby
  # adds route -> controller action -> model function
  member_action :activate, method: :put do
    resource.switch_active!
    redirect_to resource_path, notice: "Active status changed to #{resource.active}"
  end

  # adds button to SHOW view
  action_item :mark_active, only: :show do |model|
    link_to "#{resource.active? ? 'deactivate!' : 'activate!'}", [:activate, :admin, resource], method: :put
  end

  # adds button to index view
  index do
  	id_column
    column :mark_active do |model|
      link_to "#{model.active? ? 'deactivate!' : 'activate!'}", [:activate, :admin, model], method: :put
    end
  end

  # conditionally display button
  # action_item :activate, only: :show, if: proc { !resource.active? } do
  #   link_to 'Activate', [:activate, :admin, resource], method: :put
  # end
```

### 12. Avoid N+1

app/admin/menu_items.rb
```ruby
  includes :menu_category
```

### 13. Add associations to DEFAULT filters in index view

config/initializers/active_admin.rb:294
```ruby
  config.include_default_association_filters = true
```

### Generator options

```sh
rails generate active_admin:assets
rails generate active_admin:devise
rails generate active_admin:install
rails generate active_admin:page
rails generate active_admin:resource
rails generate active_admin:webpacker
```