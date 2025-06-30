---
layout: post
title: "Separate Google and Youtube oAuth"
author: Yaroslav Shmarov
tags: oauth omniauth devise google youtube
thumbnail: /assets/thumbnails/turbo.png
---

In this scenario, I want to allow users to authenticate with **google**, but also connect **Youtube** accounts.

google-and-youtube-oauth.png

gem "omniauth-google-oauth2" does not provide a separate youtube oauth strategy.

The google oauth strategy distinguishes Google vs Youtube oauth only by scopes.

- `https://www.googleapis.com/auth/youtube.readonly` - scope to access basic youtube account data. can be used for auth or "validate ownership".
- `https://www.googleapis.com/auth/youtube.force-ssl` - write access to youtube account

Google oauth screen:

google-oauth-personal.png

Youtube oauth screen

assets/images/google-oauth-youtube.png

So to separate these oauth strategies, we can create a custom youtube oauth strategy on top of google:

```ruby
# config/initializers/omniauth.rb
require "omniauth"
require "omniauth-google-oauth2"

module OmniAuth
  module Strategies
    class Youtube < OmniAuth::Strategies::GoogleOauth2
      option :name, "youtube"

      def initialize(app, *args, &block)
        super
        options.scope = "email,profile,https://www.googleapis.com/auth/youtube.readonly"
        # options.scope = "email,profile,https://www.googleapis.com/auth/youtube.force-ssl,https://www.googleapis.com/auth/youtube.readonly"

        # Use the same redirect URI as Google OAuth2
        # options.redirect_uri = "http://localhost:3000/users/auth/youtube/callback"
        # options.redirect_uri = "http://localhost:3000/users/auth/google_oauth2/callback"
        # options.redirect_uri = "https://contentprize.com/users/auth/youtube/callback"
      end
    end
  end
end
```

Add it as a separate oauth strategy in devise:

```ruby
# config/initializers/devise.rb
  config.omniauth :google_oauth2,
                  Rails.application.credentials.dig(:google_oauth2, :key),
                  Rails.application.credentials.dig(:google_oauth2, :secret),
                  scope: "email,profile"

  # Add YouTube as a separate provider using the same Google credentials
  config.omniauth :youtube,
                  Rails.application.credentials.dig(:google_oauth2, :key),
                  Rails.application.credentials.dig(:google_oauth2, :secret)
```

Ensure that youtube is also present in the list of devise oauth providers in the User model:

```ruby
# app/models/user.rb
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable,
           :omniauthable, omniauth_providers: Devise.omniauth_configs.keys
```

In the google cloud console, add separate callback urls to both providers:

google-and-youtube-oauth-callbacks.png

Handle

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  Devise.omniauth_configs.keys.each do |provider|
    define_method provider do
      handle_auth provider
    end
  end

  def failure
    redirect_to new_user_registration_url, alert: "Something went wrong. Try again."
  end

  private

  def handle_auth(kind)
    auth_payload = request.env["omniauth.auth"]

    # NOT IMPLEMENTED: handle logic for User having multiple oauth providers here
    user = User.from_omniauth(auth_payload)
    if user.persisted?
      flash[:notice] = "Success"
      sign_in_and_redirect user, event: :authentication
    else
      redirect_to new_user_registration_url, alert: user.errors.full_messages.join("\n")
    end
  end
end
```
