---
layout: post
title: "ONLY Omniauth login with Devise (without email registration)"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails devise omniauth
thumbnail: /assets/thumbnails/devise.png
---

I don't recommend using omniathu without devise. Security. So here's how we set it up with devise.

### 1. Initial setup

```sh
rails new omnify -d=postgresql
cd omnify
rails db:setup
```

```sh
rails g controller static_pages landing_page
```

routes.rb
```ruby
  root 'static_pages#landing_page'
```

```sh
bundle add devise
rails g devise:install
rails generate devise User
rails db:migrate
```

application.html.erb
```ruby
  <%= notice %>
  <%= alert %>
  <% if current_user %>
    <%= link_to current_user.email, edit_user_registration_path %>
    <%= link_to "Log out", destroy_user_session_path, method: :delete %>
  <% else %>
    <%= link_to "Log in", new_user_session_path %>
    <%= link_to "Register", new_user_registration_path %>
  <% end %>
```

### 2. [Add login with github](https://blog.corsego.com/devise-omniauth-github)

### 3. Finally, allow login ONLY with social (github in our case)

[Devise Wiki - only omniauth](https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview#using-omniauth-without-other-authentications)

Disable unused devise routes in routes.rb:
```ruby
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"},
    skip: [:sessions, :registrations]
```

Disable unused devise resources in user.rb:
```ruby
devise :database_authenticatable,
       #:registerable,
       #:recoverable,
       :rememberable,
       #:validatable,
       :omniauthable, omniauth_providers: [:github]
```

This will disable the `users/sign_up` routes.

`users/sign_in` will still work. Existing users will still see a field to sign in.

You might want to generate the devise views for `users/sessions/new` and remove the login form, if you want only social login:

```sh
rails generate devise:views -v sessions
```

### 4. BONUS. Optionally: Modify generated devise resources in routes.rb.

Now you have the following routes:

```sh
rails routes | grep devise
```

```sh
new_user_session GET          /users/sign_in(.:format)    devise/sessions#new
user_session POST             /users/sign_in(.:format)    devise/sessions#create
destroy_user_session DELETE   /users/sign_out(.:format)   devise/sessions#destroy
```

That translate to:

routes.rb
```
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"},
    skip: [:sessions, :registrations]

  # as :user do
  devise_scope :user do
    get "/users", to: "devise/sessions#new", as: :new_user_session
    post "/users/sign_in", to: "devise/sessions#create", as: :user_session
    delete "/users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
```

You might want to disable the `get` route to remove `users/sign_in` - Not really recommended.

[Using `devise_for`](https://www.rubydoc.info/github/plataformatec/devise/ActionDispatch%2FRouting%2FMapper:devise_for)
