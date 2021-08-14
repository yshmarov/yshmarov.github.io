---
layout: post
title: "gem Draper: abstract view logic from the model"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails draper views decorators
thumbnail: /assets/thumbnails/drapes.png
---

## Problem

* Presentation (View) logic does not belong in a model!
* app/helpers/users_helper is as global as app/helpers/application_helper... Why?!
* code from app/helpers is auto-included in views, but not controllers/models

## Solution:

* Use [gem draper](https://github.com/drapergem/draper){:target="blank"}'s decorators to separate presentation logic and call it when needed

## Example:

### 1 - BAD

```
/app/models/user.rb

  def username
    return name if name.present?
    email.split('@')[0]
  end

# or

/app/helpers/users_helper.rb

  def username
    return name if name.present?
    email.split('@')[0]
  end
```

### 2 - GOOD

```
/app/decorators/user_decorator.rb

  def username
    return name if name.present?
    email.split('@')[0]
  end
```

## Installation

Gemfile
```
  gem 'draper'
```

console
```
bundle
rails generate draper:install
rails generate decorator User
```

## Getting generators to work:

initialize the decorator in a controller:
```
# app/controllers/users_controller.rb

  def index
    @users = User.all.decorate
  end

  def show
    @user = User.friendly.find(params[:id]).decorate
  end
```

OR more complex - with pagy and ransack:
```
# app/controllers/users_controller.rb

  def index
    @q = User.all.ransack(params[:q])
    @pagy, @users = pagy(@q.result(distinct: true)
    @users = @users.decorate
  end
```

Now you can call (in a view):
```
  <%= @user.username %>
```

OR decorate a signle call (in a view):
```
  <%= current_user.decorate.username %>
```

Example of calling associations, decorating a price:

app/decorators/user_decorator.rb
```
class PostDecorator < Draper::Decorator
  # belongs_to :user
  # has_many :comments

  delegate_all

  decorates_association :user, with: UserDecorator
  decorates_association :comments #, with: CommentDecorator

  def price
    h.number_to_currency(price, precision: 0)
  end
end
```

**More real-life usage examples coming later.**

Useful Resources:
* [another post with some good examples](https://qiita.com/asukiaaa/items/b9f093de590e5a00e5d7){:target="blank"}
