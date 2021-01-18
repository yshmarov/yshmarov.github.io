---
layout: post
title: One hash field to manage all user roles
author: Yaroslav Shmarov
tags: ruby-on-rails jsonb store_accessor
thumbnail: /assets/thumbnails/curlybrackets.png
---

You can use a gem like `rolify` or try to add a few `role` fields to the `users` table, 
** but there is a better way **:

![user-roles-one-field](/assets/2021-01-11-user-roles-one-field/user-roles-one-field.PNG)

migration:
```
rails g migration add_roles_to_users
```
```
class AddRolesToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :roles, :jsonb, null: false, default: {}
    add_index  :users, :roles, using: :gin
  end
end
```
app/models/concerns/roleable.rb:
```
module Roleable

  extend ActiveSupport::Concern
  included do
    # List user roles
    ROLES = [:admin, :teacher, :student]
  
    # json column to store roles 
    store_accessor :roles, *ROLES
  
    # Cast roles to/from booleans
    ROLES.each do |role|
      scope role, -> { where("roles @> ?", {role => true}.to_json) }
      define_method(:"#{role}=") { |value| super ActiveRecord::Type::Boolean.new.cast(value) }
      define_method(:"#{role}?") { send(role) }
    end
  
    def active_roles # Where value true
      ROLES.select { |role| send(:"#{role}?") }.compact
    end
  
    # role validation
    validate :must_have_a_role, on: :update
    validate :must_have_an_admin
  
    private
  
    def must_have_an_admin
      if persisted? &&
          (User.where.not(id: id).pluck(:roles).count { |h| h["admin"] == true } < 1) &&
          roles_changed? && admin == false
        errors.add(:base, "There should be at least one admin")
      end
    end
  
    def must_have_a_role
      if roles.values.none?
        errors.add(:base, "A user must have at least one role")
      end
    end
  end
end
```
app/models/user.rb:
```
  include Roleable
```
whitelist editing roles in the controller: 
```
  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated."
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(*User::ROLES)
  end
```
app/views/users/edit.html.erb:
```
<%= form_for(@user) do |f| %>

  <% if @user.errors.any? %>
    <div id="error_explanation">
      <h2>
        <%= pluralize(@user.errors.count, "error") %>
        prohibited this user from being saved:
      </h2>
      <ul>
        <% @user.errors.full_messages.each do |message| %>
          <li>
            <%= message %>
          </li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <% User::ROLES.each do |role| %>
    <label>
      <%= f.check_box role %>
      <%= role.to_s.humanize %>
    </label>
    <br>
  <% end %>

  <%= f.button :submit %>

<% end %>
```
add a role in the console
```
User.first.update(admin: true)
```
list roles in a view:
```
<%= user.active_roles.join(", ") %>
<%= user.roles %>
<%= user.roles.class %>
<%= user.admin? %>
<% if user.admin? || user.viewer? %>
  admin or viewer
<% end %>
<%= current_user.admin? %>
```
controller validation for authorization:
```
  before_action :only_admin, only: [:edit, :update]
  def only_admin
    unless current_user.admin?
      redirect_to dashboard_path, notice: "Not authorized!"
    end
  end
```

Helpful materials:
* [https://melvinchng.github.io/rails/RailsJSONB.html#43-use-jsonb-column-to-in-form](https://melvinchng.github.io/rails/RailsJSONB.html#43-use-jsonb-column-to-in-form){:target="blank"}
* [https://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails](https://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails){:target="blank"}
* [https://guides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb](https://guides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb){:target="blank"}
* [https://ruby-doc.org/core-2.5.1/Hash.html](https://ruby-doc.org/core-2.5.1/Hash.html){:target="blank"}
* This method was partially inspired by Jumpstart app
