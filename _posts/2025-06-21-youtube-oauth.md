---
layout: post
title: "Separate Google and YouTube OAuth Strategies in Rails"
author: Yaroslav Shmarov
tags: oauth omniauth devise google youtube rails
thumbnail: /assets/thumbnails/oauth.png
---

Sometimes you need to allow users to authenticate with **Google** while also connecting their **YouTube** accounts separately. This can be tricky because the `omniauth-google-oauth2` gem doesn't provide a separate YouTube OAuth strategy.

## The Challenge

The Google OAuth strategy distinguishes between Google and YouTube OAuth only by scopes:

- `https://www.googleapis.com/auth/youtube.readonly` - Access basic YouTube account data (can be used for auth or "validate ownership")
- `https://www.googleapis.com/auth/youtube.force-ssl` - Write access to YouTube account

Here's what the OAuth screens look like:

**Google OAuth screen:**
![Google OAuth Personal](/assets/images/google-oauth-personal.png)

**YouTube OAuth screen:**
![Google OAuth YouTube](/assets/images/google-oauth-youtube.png)

## Solution: Custom YouTube OAuth Strategy

To separate these OAuth strategies, we can create a custom YouTube OAuth strategy on top of the Google OAuth2 strategy:

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
        # For write access, use:
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

## Configure Devise

Add YouTube as a separate OAuth strategy in your Devise configuration:

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

## Update User Model

Ensure that YouTube is included in the list of Devise OAuth providers:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: Devise.omniauth_configs.keys
end
```

## Google Cloud Console Setup

In the Google Cloud Console, add separate callback URLs for both providers:

![Google and YouTube OAuth Callbacks](/assets/images/google-and-youtube-oauth-callbacks.png)

## Handle OAuth Callbacks

Create a controller to handle both Google and YouTube OAuth callbacks:

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

    # TODO: Handle logic for User oAuth
    user = User.from_omniauth(auth_payload)

    if user.persisted?
      flash[:notice] = "Successfully authenticated with #{kind.titleize}!"
      sign_in_and_redirect user, event: :authentication
    else
      redirect_to new_user_registration_url, alert: user.errors.full_messages.join("\n")
    end
  end
end
```

This way users can authenticate with **Google** or **Youtube**
