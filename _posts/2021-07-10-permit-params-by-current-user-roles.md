---
layout: post
title: "Quick tip: Permit params by current user roles"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails authorization roles params
thumbnail: /assets/thumbnails/ransack.png
---

Scenario: restrict users with different roles to modifying specific data inside an Object.

## Option 1 (my way):

users_controller.rb:

```ruby
  def user_params
    list_allowed_params = []
    list_allowed_params += [:name] if current_user == @user || current_user.admin?
    list_allowed_params += [:role, :salary] if current_user.admin?
    params.require(:user).permit(list_allowed_params)
  end
```

## Option 2 (alternative):

users_controller.rb:

```ruby
  ADMIN_ATTRIBUTES = [:a, :b, :c, :d]
  MANAGER_ATTRIBUTES = [:a, :c, :d]
  EDITOR_ATTRIBUTES = [:b, :d]
  
  def user_params
    case current_user.role
    when :admin
      params.require(:user).permit(ADMIN_ATTRIBUTES)
    when :manager
      params.require(:user).permit(MANAGER_ATTRIBUTES)
    when :editor
      params.require(:user).permit(EDITOR_ATTRIBUTES)
    end
  end
```
