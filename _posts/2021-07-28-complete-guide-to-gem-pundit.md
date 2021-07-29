---
layout: post
title: "Rails authorization with gem Pundit"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails pundit authorization roles
thumbnail: /assets/thumbnails/stop-sign.png
---

As I know, Pundit and CanCanCan are the 2 best approaches to adding AUTHORIZATION into a Rails app.

AUTHORIZATION - allow users to perform different actions / see different content based on their roles / other conditions.

I personally just prefer Pundit.

# 1. Basic installation & usage:

Gemfile
```
 gem "pundit"
```

console
```
bundle
rails g pundit:install
rails g pundit:policy post
rails g pundit:policy user
```

app/controllers/application_controller.rb
```
  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
```

app/policies/post_policy.rb
```
class PostPolicy < ApplicationPolicy
  def index?
    true
    # false - nobody has access
  end

  def show?
    @user.has_any_role? :admin, :newuser || @record.user == @user
    # index?
    # @user.has_role? :admin
  end
end
```

app/controllers/posts_controller.rb
```
  def index
    @posts = Post.order(created_at: :desc)
    authorize @posts
  end

  def show
    authorize @post
  end

  ...
```

# 2. Pundit policy scopes

This allows you to let users with different authorizations to see different scopes of items.

Below example - admins can see all posts, other users can see posts that have content not blank.

app/policies/post_policy.rb
```
class PostPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if @user.has_role? :admin
        scope.all
      else
        scope.where.not(content: "")
      end
    end
  end
```

app/controllers/posts_controller.rb
```
  def index
    @posts = policy_scope(Post).order(created_at: :desc)
    authorize @posts
  end
  ...
```

In the above case `@record` = selected post

# 3. View validation

Allow users different authorizations to see content in a view:

views:
```
<b>current user can see particular users show page?</b>
<%= policy(@user).show? %>

<b>current user can see users index?</b>
<%= policy(User).index? %>

<b>current user can edit a user?</b>
<%= policy(User).edit? %>

<%= link_to 'Edit user roles', edit_user_path(user) if policy(User).edit? %>
```
