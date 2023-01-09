---
layout: post
title: "Omniauth without Devise"
author: Yaroslav Shmarov
tags: ruby-on-rails devise omniauth github
thumbnail: /assets/thumbnails/devise.png
---

Previously I've covered [Github omniauth with Devise]({% post_url 2021-05-31-devise-omniauth-github %}){:target="blank"}, and [only github omniauth with Devise (without email-based registration)]({% post_url 2021-10-23-devise-login-only-with-omniauth %}){:target="blank"}.

An even **simpler** solution would be to sign in via a social login provider **without Devise** at all! Here's the easiest way to do it.

First, add the [`gem omniauth`](https://github.com/omniauth/omniauth){:target="blank"} gems:

```ruby
# Gemfile
gem 'omniauth-github', github: 'omniauth/omniauth-github', branch: 'master'
gem "omniauth-rails_csrf_protection", "~> 1.0"
```

If you are using Github omniauth, you can generate API credentials [**here**](https://github.com/settings/applications/new)

For development environment you can use

Homepage URL:
`http://localhost:3000`
Authorization callback URL
`http://localhost:3000/auth/github/callback`

Add your social provider API credentials to the Rails app:

```ruby
# echo > config/initializers/omniauth.rb
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, "GITHUB_ID", "GITHUB_SECRET"
end
```

Create a user model.
We will also add a few static pages:
* `/landing_page` that can be accessed without authentication
* `/dashboard` that requires authentication

```ruby
rails g controller static_pages landing_page dashboard
rails g model User email github_uid
```

Routes:

```ruby
# config/routes.rb
  root 'static_pages#landing_page'
  get 'dashboard', to: 'static_pages#dashboard'

  get 'auth/github/callback', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  # get 'login', to: redirect('/auth/github'), as: 'login'
```

Gems like devise provide some default methods, that we will have to add on our own now:
* `def current_user` - get the current user from session params.
* `def user_signed_in?` - check if there is a current user.
* `def require_authentication` - to restrict controller actions for non-authenticated users.
* `helper_method :current_user` - to make `current_user` available in views.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user

  def require_authentication
  	redirect_to root_path, alert: 'Requires authentication' unless user_signed_in?
  end

  def current_user
  	@current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
  	# converts current_user to a boolean by negating the negation
  	!!current_user
  end
end
```

The button to `/auth/github` will redirect to the github login page.

```ruby
# app/views/layouts/application.html.erb
<%= link_to 'Home', root_path %>
<% if current_user %>
  <%= current_user.email %>
  <%= link_to 'Dashboard', dashboard_path %>
  <%= button_to 'Logout', logout_path, method: :delete, data: { turbo: false } %>
<% else %>
  <%= button_to "Sign in with Github", "/auth/github", data: { turbo: false } %>
<% end %>
```

After successful authentication, the user should be redirected to `sessions#create` with `request.env['omniauth.auth']`.

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    @user = User.from_omniauth(request.env['omniauth.auth'])
    if @user.persisted?
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Logged in as #{@user.email}"
    else
      redirect_to root_url, alert: 'Failure'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end
```

`from_omniauth` will find the users `email` and `uid` in the data provided by github, and find or create the user.

```ruby
# app/models/user.rb
class User < ApplicationRecord
  validates :github_uid, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true, uniqueness: true

  def self.from_omniauth(access_token)
    github_uid = access_token.uid
    data = access_token.info
    email = data['email']

    User.find_or_create_by(email:, github_uid:)
  end
end
```

Finally, require authentication to visit `/dashboard`:

```ruby
# app/controllers/static_pages_controller.rb
class StaticPagesController < ApplicationController
  before_action :require_authentication, only: :dashboard

  def landing_page
  end

  def dashboard
  end
end
```

That's it! Now you can use omniauth without devise!
