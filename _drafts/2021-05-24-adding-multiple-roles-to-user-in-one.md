---
layout: post
title: Adding multiple roles to a user in one field
author: Yaroslav Shmarov
tags: 
---


Helpful materials:
* [](https://melvinchng.github.io/rails/RailsJSONB.html#43-use-jsonb-column-to-in-form)
* [](https://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails)
* [](https://guides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb)


* [rails hash](https://ruby-doc.org/core-2.5.1/Hash.html)

migration:
```
class AddRolesToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :roles, :jsonb, null: false, default: {}
    add_index  :users, :roles, using: :gin
  end
end
```

member.rb
```
  # List user roles
  ROLES = [:admin, :viewer]

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
```
controller whitelist
```
    def user_params
      params.require(:user).permit(*User::ROLES)
    end
```
form
```
  <div class="form-group">
    <% User::ROLES.each do |role| %>
      <label>
        <%= f.check_box role %>
        <%= role.to_s.humanize %>
      </label>
      <br>
    <% end %>
  </div>
```
list roles in a view
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
controller validation 
```
  before_action :only_admin, only: [:index]
  def only_admin
    current_member = Member.where(user: current_user).first
    unless current_member.admin?
      redirect_to dashboard_path, notice: "Not authorized!"
    end
  end
```
