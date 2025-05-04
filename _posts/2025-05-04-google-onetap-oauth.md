---
layout: post
title: Google One Touch Authentication with Rails 8 and Devise
author: Yaroslav Shmarov
tags: google oauth omniauth
thumbnail: /assets/thumbnails/google.png
---

Let's implement google auth popup:

![google-one-touch-preview](/assets/images/google-one-touch-preview.png)

### 1. Google oAuth

```ruby
# Gemfile
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection" # for omniauth 2.0
```

```ruby
# config/initializers/devise.rb
  config.omniauth :google_oauth2, Rails.application.credentials.dig(:google_oauth2, :key),
                  Rails.application.credentials.dig(:google_oauth2, :secret)
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :invitable, :database_authenticatable,
    :rememberable, :validatable,
    :omniauthable, omniauth_providers: [ :google_oauth2 ]
end
```

```ruby
# app/models/user.rb
  def from_omniauth(auth_payload)
    data = auth_payload.info
    user = User.where(email: data["email"]).first_or_initialize do |user|
      user.email = data["email"]
      user.password = Devise.friendly_token[0, 20] if user.password.blank?
    end

    user.name = auth_payload.info.name
    user.image = auth_payload.info.image
    user.provider = auth_payload.provider
    user.uid = auth_payload.uid
    user.save
    user
  end
```

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth "Google"
  end

  def handle_auth(kind)
    user = User.from_omniauth(request.env["omniauth.auth"])
    if user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: kind
      sign_in_and_redirect user, event: :authentication
    else
      session["devise.auth_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to root_path, alert: user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: "Failure. Please try again"
  end
end
```

```ruby
<%= button_to "Sign in with Google", "/users/auth/google_oauth2", method: :post, data: { turbo: "false" } %>
```

```diff
# config/routes.rb
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [ :sessions, :registrations ]
  devise_scope :user do
    delete "/users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
```

### 2. Google oAuth popup

First, allow JS origins for development & production in the [Google API Dashboard](https://console.cloud.google.com/apis/dashboard)

![google-one-touch-authorize](/assets/images/google-one-touch-authorize.png)

```diff
# config/routes.rb
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [ :sessions, :registrations ]
   devise_scope :user do
    delete "/users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
+     post "/google_onetap_callback", to: "users/omniauth_callbacks#google_onetap", as: :google_onetap_callback
   end
```

```html
<!-- app/views/shared/\_google_onetap_button.html.erb -->
<script src="https://accounts.google.com/gsi/client" async defer></script>
<div
  id="g_id_onload"
  data-client_id="<%= Rails.application.credentials.dig(:google_oauth2, :key) %>"
  data-login_uri="<%= google_onetap_callback_url %>"
  data-authenticity_token="<%= form_authenticity_token %>"
  data-itp_support="true"
></div>
```

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_onetap
    if g_csrf_token_valid?
      payload = Google::Auth::IDTokens.verify_oidc(params[:credential], aud: Rails.application.credentials.dig(:google_oauth2, :key))
      user = User.from_google_onetap(payload)
      if user.persisted?
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Google"
        sign_in_and_redirect user, event: :authentication
      else
        redirect_to root_path, alert: user.errors.full_messages.join("\n")
      end
    else
      redirect_to root_path, alert: "Failure. Please try again"
    end
  end

  private

  def g_csrf_token_valid?
    cookies["g_csrf_token"] == params["g_csrf_token"]
  end
end
```

The payload for onetap is not the same as for classic oauth

```ruby
# app/models/user.rb
def from_google_onetap(payload)
  user = User.where(email: payload["email"]).first_or_initialize do |user|
    user.email = payload["email"]
    user.password = Devise.friendly_token[0, 20] if user.password.blank?
  end

  user.name = payload["name"]
  user.image = payload["picture"]
  user.provider = "google_oauth2"
  user.uid = payload["sub"]
  user.save
  user
end
```

Inspired by [patrickkarsh's post](https://patrickkarsh.medium.com/how-to-add-google-one-touch-authentication-to-a-ruby-on-rails-application-6ac8776c4190).
