---
layout: post
title: Custom devise invitable
author: Yaroslav Shmarov
tags: ruby-on-rails jsonb store_accessor
thumbnail: /assets/thumbnails/curlybrackets.png
---

gemfile:
```
gem 'devise_invitable', '~> 2.0.0'
```
console:
```
bundle
rails generate devise_invitable:install
rails generate devise_invitable User
rails db:migrate
```
user.rb:
```
class User < ActiveRecord::Base
  devise :database_authenticatable, :confirmable, :invitable
end
```
Default: 
users/index.html.erb:
```
<%= link_to "Invite a user", new_user_invitation_path %>
```
Custom:
users/index.html.erb:
```
<%= form_tag invite_members_path, method: :get do %>
  <%= email_field_tag 'email' %>
  <%= submit_tag t(".invite") %>
<% end %>
```
users_controller.rb:
```
def invite
  email = params[:email]
  user_from_email = User.find_by(email: email)
  if email.present?
    if user_from_email.present?
      redirect_to users_path, alert: "User already exists"
    else 
      new_user = User.invite!({email: email}, current_user)
      if new_user.persisted?
        redirect_to members_path, notice: "#{email} successfully invited"
      else
        redirect_to members_path, alert: "Something went wrong. Please try again"
      end
    end
  else
    redirect_to members_path, alert: "No email provided!"
  end
end
```
routes.rb:
```
resources :users do
  get :invite, on: :collection
end
```