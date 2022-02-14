---
layout: post
title: "Add social log in with Github (Omniauth)"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails devise omniauth github
thumbnail: /assets/thumbnails/github-logo.png
---

[omniauth github gem](https://github.com/omniauth/omniauth-github){:target="blank"}

### Installation:

First, [create a github oauth app](https://github.com/settings/applications/new){:target="blank"}.

example callback url: `https://superails.com/users/auth/github/callback`

![creating a github oauth app](/assets/devise-omniauth-github/create-git-app.png)

/Gemfile
```ruby
gem 'omniauth-github', github: 'omniauth/omniauth-github', branch: 'master'
gem "omniauth-rails_csrf_protection" # for omniauth 2.0
```
/config/initializers/devise.rb
```ruby
  config.omniauth :github, 'APP_ID', 'APP_SECRET'
```
/config/routes.rb
```ruby
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"}
```
/app/controllers/users/omniauth_callbacks_controller.rb
```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    handle_auth "Github"
  end

  def handle_auth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: kind
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.auth_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: "Failure. Please try again"
  end
end
```
/app/models/user.rb
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github]

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data["email"]).first

    user ||= User.create(
      email: data["email"],
      password: Devise.friendly_token[0, 20]
    )

    user.name = access_token.info.name
    user.image = access_token.info.image
    user.provider = access_token.provider
    user.uid = access_token.uid
    user.save

    user
  end
end
```
console
```
rails g migration add_omniauth_data_to_users name image provider uid
```
views
```ruby
<% if user_signed_in? %>
  <%= image_tag current_user.image, size: '30x30', alt: "#{current_user.email}" if current_user.image? %>
  <%= current_user.name %>
  <%= current_user.uid %>
  <%= current_user.provider %>
<% else %>
  <%= link_to "Sign in with Github", omniauth_authorize_path(User, :github), method: :post, data: { disable_with: "Connecting..." } %>
<% end %>
```