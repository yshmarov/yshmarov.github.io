---
layout: post
title: "Edit Rolify roles for a User"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails rolify
thumbnail: /assets/thumbnails/ransack.png
---

Let's say you assing User roles via Ransack.

Example code for editing user roles:

app/controllers/users_controller.rb

```ruby
  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    if @user.update(user_params)
      redirect_to users_url, notice: "User was successfully updated."
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit({role_ids: []})
  end
```

app/views/users/edit.html.haml

```ruby
<%= simple_form_for @user do |f| %>
  <%= f.collection_check_boxes :role_ids, Role.all, :id, :name %>
  <%= f.error :roles %>
  <%= f.button :submit %>
```

OR app/views/users/edit.html.haml

```ruby
<%= simple_form_for @user do |f| %>
  <% Role.all.each do |role| %>
    <%= check_box_tag "user[role_ids][]", role.id, @user.role_ids.include?(role.id) %>
    <%= role.name %>
    <%= role.resource_type %>
    <%= role.resource %>
  <% end %>
  <%= f.button :submit %>
<% end %>
```

display all user roles in a view:

```ruby
- @user.roles.each do |role|
  = role.name

@user.roles.pluck(:name)
```
app/models/user.rb

```ruby
validate :must_have_a_role, on: :update

private

def must_have_a_role
  unless roles.any?
    errors.add(:roles, "must have at least one role")
  end
end

after_create do
  if User.count == 1
    add_role(:admin) if roles.blank?
  end
  add_role(:teacher)
  add_role(:student)
end
```
