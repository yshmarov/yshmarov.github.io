---
layout: post
title: "Rails 8 Authentication generator: user registration"
author: Yaroslav Shmarov
tags: rails devise authentication
thumbnail: /assets/thumbnails/lock.png
---

Previously I wrote about the [new Rails Sessions generator]({% post_url 2024-07-19-rails-8-authentication %}).

Currently the generator allows email-password log in for existing users. It does not tackle registrations.

Let's add registrations!

First, add a new `registration` route:

```diff
# config/routes.rb
Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
+  resource :registration, only: %i[new create]
```

The `registrations_controller` will be a lot like `sessions_controller`, but instead of finding a User, we will create one.

```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session, only: :new
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
    redirect_to root_url, notice: "You are already signed in." if authenticated?
  end

  def create
    user = User.new(params.permit(:email_address, :password))
    if user.save
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Signed up."
    else
      redirect_to new_registration_url(email_address: params[:email_address]), alert: user.errors.full_messages.to_sentence
    end
  end
end
```

Now you can add a "Sign up" link in your navbar:

```diff
    <%= link_to 'Home', root_path %>
    <%= link_to 'Dashboard', dashboard_path %>
    <% if authenticated? %>
      <%#= Current.session %>
      <%= Current.user.email_address %>
      <%= button_to 'Sign out', session_path, method: :delete %>
    <% else %>
      <%= link_to 'Sign in', new_session_path %>
+      <%= link_to 'Sign up', new_registration_path %>
    <% end %>
```

Create the `sign_up` form. It will be the same as the `sign_in` form, just with a different `url`:

```ruby
# app/views/registrations/new.html.erb
<h1>
  Sign up
</h1>

<%= form_with url: registration_url do |form| %>
  <div>
    <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "email", placeholder: "Enter your email address", value: params[:email_address] %>
  </div>

  <div>
    <%= form.password_field :password, required: true, autocomplete: "new-password", placeholder: "Create a password", maxlength: 72 %>
  </div>

  <%= form.submit "Sign up" %>
<% end %>
```

Finally, validate User email address to show validation errors:

```diff
# app/models/user.rb
+  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
```

That's it! Now your users can both sign in **and** sign up to your app.

Although you will most likely want to add password reset flow & email confirmation flow to make this solution viable for a real app.

I still recommend using [gem Devise](https://github.com/heartcombo/devise) for email-password authentication.
