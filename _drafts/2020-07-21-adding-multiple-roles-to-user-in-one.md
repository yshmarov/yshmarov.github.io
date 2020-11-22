---
layout: post
title: Adding multiple roles to a user in one field
date: '2020-07-21T23:49:00.000+02:00'
author: yaro_the_slav
tags: 
modified_time: '2020-07-21T23:49:27.708+02:00'
blogger_id: tag:blogger.com,1999:blog-5936476238571675194.post-3027332309286193552
blogger_orig_url: https://blog.corsego.com/2020/07/adding-multiple-roles-to-user-in-one.html
---


Helpful materials:
https://melvinchng.github.io/rails/RailsJSONB.html#43-use-jsonb-column-to-in-form

https://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails 

https://guides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb

rails hash
https://ruby-doc.org/core-2.5.1/Hash.html

migration:

class AddRolesToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :roles, :jsonb, null: false, default: {}
    add_index  :users, :roles, using: :gin
  end
end


member.rb

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

controller whitelist

    def user_params
      params.require(:user).permit(*User::ROLES)
    end

form

  <div class="form-group">
    <% User::ROLES.each do |role| %>
      <label>
        <%= f.check_box role %>
        <%= role.to_s.humanize %>
      </label>
      <br>
    <% end %>
  </div>

list roles in a view

            <%= user.active_roles.join(", ") %>
            <%= user.roles %>
            <%= user.roles.class %>
            <%= user.admin? %>
            <% if user.admin? || user.viewer? %>
              admin or viewer
            <% end %>

f
<%= current_user.admin? %>

controller validation 


  before_action :only_admin, only: [:index]
  def only_admin
    current_member = Member.where(user: current_user).first
    unless current_member.admin?
      redirect_to dashboard_path, notice: "Not authorized!"
    end
  end
