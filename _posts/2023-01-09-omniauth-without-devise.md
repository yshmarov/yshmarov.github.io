---
layout: post
title: "Omniauth without Devise"
author: Yaroslav Shmarov
tags: ruby-on-rails devise omniauth github testing
thumbnail: /assets/thumbnails/devise.png
youtube_id: 9bOzMgkULXs
---

Previously I've covered [Github omniauth with Devise]({% post_url 2021-05-31-devise-omniauth-github %}){:target="blank"}, and [only github omniauth with Devise (without email-based registration)]({% post_url 2021-10-23-devise-login-only-with-omniauth %}){:target="blank"}.

An even **simpler** solution would be to sign in via a social login provider **without Devise** at all! Here's the easiest way to do it.

Before at [superails.com](https://superails.com/) was using devise and omniauth, but for simplicity (I do not want to manage user passwords, confirm accounts via email) I decided to remove devise and keep only oAuth login!

This is how I moved to oAuth-only login.

First, add the [`gem omniauth`](https://github.com/omniauth/omniauth){:target="blank"} gems:

```ruby
# Gemfile
gem 'omniauth-github', github: 'omniauth/omniauth-github', branch: 'master'
gem 'omniauth-google-oauth2'
gem "omniauth-rails_csrf_protection", "~> 1.0"
```

If you are using Github omniauth, you can generate API credentials [**here**](https://github.com/settings/applications/new){:target="blank"}

For development environment you can use

Homepage URL:
```
http://localhost:3000
```

Authorization callback URLs
```
http://localhost:3000/auth/github/callback
http://localhost:3000/auth/google_oauth2/callback
```

Add your social provider API credentials to the Rails app:

```ruby
# echo > config/initializers/omniauth.rb
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, "GITHUB_ID", "GITHUB_SECRET"
  provider :google_oauth2, "GOOGLE_ID", "GOOGLE_SECRET"
end
```

Create a user model.
We will also add a few static pages:
* `/landing_page` that can be accessed without authentication
* `/dashboard` that requires authentication

```ruby
rails g controller static_pages landing_page dashboard
rails g model User provider uid name email image
```

Routes:

```ruby
# config/routes.rb
  root 'static_pages#landing_page'
  get 'dashboard', to: 'static_pages#dashboard'

  get 'auth/github/callback', to: 'sessions#create'
  get 'auth/google_oauth2/callback', to: 'sessions#create'
  get 'auth/failure', to: 'sessions#failure'
  delete 'sign_out', to: 'sessions#destroy'
  # get 'login', to: redirect('/auth/github'), as: 'login'
```

Gems like devise provide some default methods, that we will have to add on our own now:
* `def current_user` - get the current user from session params.
* `def user_signed_in?` - check if there is a current user.
* `def authenticate_user!` - to restrict controller actions for non-authenticated users.
* `helper_method :current_user` - to make `current_user` available in views.
* `helper_method :user_signed_in` - to make `user_signed_in` available in views.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user
  helper_method :user_signed_in?

  def authenticate_user!
    redirect_to root_path, alert: "Requires authentication" unless user_signed_in?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
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
  <%= button_to 'Logout', sign_out_path, method: :delete, data: { turbo: false } %>
<% else %>
  <%= button_to "Sign in with Github", "/auth/github", data: { turbo: false } %>
  <%= button_to "Sign in with Google", "/auth/google_oauth2", data: { turbo: false } %>
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
      redirect_path = request.env['omniauth.origin'] || dashboard_path
      redirect_to redirect_path, notice: "Logged in as #{@user.name}"
    else
      redirect_to root_url, alert: "Failure"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out"
  end

  def failure
    redirect_to root_path, alert: "Failure"
  end
end
```

`from_omniauth` will find the users `email` and `uid` in the data provided by github/google, and find or create the user.

```ruby
# app/models/user.rb
class User < ApplicationRecord
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true, uniqueness: true

  def self.from_omniauth(omniauth_params)
    # TODO: what if 2 providers have same email?
    # TODO: what if email is not present in the omniauth payload?
    provider = omniauth_params.provider
    uid = omniauth_params.uid

    user = User.find_or_initialize_by(provider:, uid:)
    user.email = omniauth_params.info.email
    user.name = omniauth_params.info.name
    user.image = omniauth_params.info.image
    user.save
    user
  end
end
```

Finally, require authentication to visit `/dashboard`:

```ruby
# app/controllers/static_pages_controller.rb
class StaticPagesController < ApplicationController
  before_action :authenticate_user!, only: %i[dashboard]

  def landing_page
  end

  def dashboard
  end
end
```

### Constraints

Instead of using a `before_action :authenticate_user!` on a controller level, you can authorize user on the **route** level even before the controller gets touched!

Gems like devise offer helpers like `authenticate :user` that is available inside routes out of the box.

In this case we will have to build our own route constraint that has access to `request.session`:

```ruby
# app/constraints/user_constraint.rb
class UserConstraint
  def initialize(&block)
    @block = block
  end

  def matches?(request)
    user = current_user(request)
    user.present? && @block.call(user)
  end

  def current_user(request)
    User.find_by(id: request.session[:user_id])
  end
end
```

Now we can wrap routes that require authenticated user, or admin user in this constraint:

```ruby
# config/routes.rb
  # authenticate :user, ->(user) { user.admin? } do # <- devise syntax
  constraints UserConstraint.new { |user| user.admin? } do
    mount GoodJob::Engine, at: "good_job"
    mount Avo::Engine, at: Avo.configuration.root_path
  end

  # authenticated :user do # <- devise syntax
  constraints UserConstraint.new { |user| user.present? } do
    get 'dashboard', to: 'static#dashboard'
  end
```

Nice!

### Tests

`bundle add faker` - add Gem Faker to mock Omniauth hashes like `Faker::Omniauth.github`, `Faker::Omniauth.google`.

Add some helper methods to log in as a random user, or as a defined user:

```ruby
# test/test_helper.rb
  # log in as a user from the database
  def sign_in(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: user.provider,
      uid: user.uid,
      info: {
        email: user.email
      }
    )
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    post '/auth/github'
    follow_redirect!
  end

  # random github user
  def login_with_github
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(Faker::Omniauth.github)
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    post '/auth/github'
    follow_redirect!
  end

  # random google user
  def login_with_google_oauth2
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(Faker::Omniauth.google)
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:google]
    post '/auth/google_oauth2'
    follow_redirect!
  end
```

Write a lot of tests for different scenarios:

```ruby
# test/controllers/sessions_controller_test.rb
require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # without this omniauth.origin can be set to the one in previous test (tags_url) resulting in flaky tests
    OmniAuth.config.before_callback_phase do |env|
      env['omniauth.origin'] = nil
    end
  end

  test 'authenticated github user should get dashboard' do
    assert_raises(ActionController::RoutingError) do
      get dashboard_url
    end
    # get dashboard_url
    # assert_response :redirect
    # assert_redirected_to root_url
    # assert_equal 'Requires authentication', flash[:alert]

    login_with_github

    get dashboard_url
    assert_response :success

    delete sign_out_path
    assert_response :redirect
    assert_redirected_to root_url
    assert_equal 'Signed out', flash[:notice]
  end

  test 'google auth success' do
    login_with_google_oauth2

    assert_response :redirect
    assert_redirected_to dashboard_url

    assert_match 'Logged in as', flash[:notice]
    assert_equal controller.current_user, User.last
    assert User.pluck(:email).include?(OmniAuth.config.mock_auth[:google_oauth2][:info][:email])
  end

  test 'github oauth success' do
    login_with_github

    assert_response :redirect
    assert_redirected_to dashboard_url
    email = OmniAuth.config.mock_auth[:github][:info][:email]
    name = OmniAuth.config.mock_auth[:github][:info][:name]
    assert_equal "Logged in as #{name}", flash[:notice]
    assert User.pluck(:email).include?(email)
    assert_equal controller.current_user.email, email
  end

  test 'github oauth failure' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    get '/auth/github/callback'
    follow_redirect!

    assert_response :redirect
    assert_redirected_to root_path
    assert_equal 'Failure. Please try again', flash[:alert]
    assert_nil controller.current_user
  end

  test 'github auth failure with no email' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: 'github',
      uid: '123545',
      info: {
        nickname: 'test',
        name: 'test',
        email: nil,
        image: 'https://avatars.githubusercontent.com/u/123545?v=3'
      }
    )
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    post '/auth/github'
    follow_redirect!

    assert_response :redirect
    assert_redirected_to root_url
    assert_equal 'Failure. Please try again', flash[:alert]
  end

  test 'redirect to previous page after login' do
    OmniAuth.config.before_callback_phase do |env|
      env['omniauth.origin'] = tags_url
    end

    login_with_github

    assert_response :redirect
    assert_redirected_to tags_url
  end

  test 'redirect to dashboard when origin is blank' do
    OmniAuth.config.before_callback_phase do |env|
      env['omniauth.origin'] = nil
    end

    login_with_github

    assert_response :redirect
    assert_redirected_to dashboard_url
  end
end
```

### System tests

Add a helper to log in as a user via system tests:

```ruby
# test/application_system_test_case.rb
  def login_with_oauth(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:github, {
                               provider: user.provider,
                               uid: user.uid,
                               info: { email: user.email }
                             })
    visit '/auth/github/callback'
  end
```

Add a browser test for being able to access the dashboard only as a logged in user:

```ruby
require 'application_system_test_case'

class StaticTest < ApplicationSystemTestCase
  test 'landing_page' do
    visit root_url
    assert_current_path root_path
  end

  test 'dashboard' do
    user = users(:one)
    login_with_oauth(user)

    visit dashboard_url
    assert_current_path dashboard_path
  end
end
```

### AVO authentication

```ruby
# config/initializers/avo.rb
  config.current_user_method do
    User.find_by(id: session[:user_id]) if session[:user_id]
  end
```

That's it! Now you can use omniauth without devise! FREEDOM! 🕊️
