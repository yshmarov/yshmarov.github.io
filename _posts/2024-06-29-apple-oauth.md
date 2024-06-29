---
layout: post
title: "Sign in with Apple in a Rails app"
author: Yaroslav Shmarov
tags: oauth apple ios omniauth
thumbnail: /assets/thumbnails/apple-logo.png
---

### Get Apple API keys

First of all, you need to [create an Apple Developer account](https://developer.apple.com/programs/enroll/). It costs $99/year. Greedy bastards!

1. [Create an app ID](https://developer.apple.com/account/resources/identifiers/bundleId/add/bundle). Check "Sign in with Apple"; no need to click "Edit". `Identifier` can be anything, but normally the reverse of your domain like `com.superails`.

2. [Create a service ID](https://developer.apple.com/account/resources/identifiers/serviceId/add/). `Identifier` can be anything, but normally the reverse of your domain like `com.superails.auth`. Check "Sign in with Apple"; click "Configure".

![Apple oAuth callback urls](/assets/images/apple-auth-callback-urls.png)

You will now have access to these oAuth credentials:

![apple-auth-service](/assets/images/apple-auth-service.png)

Btw, Apple oAuth will not work on localhost, so I added a [Ngrok]({% post_url 2024-02-12-ngrok %}) URL for development purposes.

3. [Create a key ID](https://developer.apple.com/account/resources/authkeys/add). Check "Sign in with Apple". You will be able to download the `pem` secret key.

![apple-auth-key](/assets/images/apple-auth-key.png)

### oAuth in your Rails app

Install the gem [omniauth-apple](https://github.com/nhosoya/omniauth-apple)

```ruby
# Gemfile
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-apple'
```

Add a callback route. Apple login should go via POST, not GET.

```diff
# config/routes.rb
-  get 'auth/apple/callback', to: 'sessions#create'
+  post 'auth/apple/callback', to: 'sessions#create'
```

```ruby
button_to 'Login with Apple', '/auth/apple'
```

For apple oAuth you will need to set `provider_ignores_state: true`.

To fix errors, you will also need to set `nonce: :local`, provided by [this PR](https://github.com/nhosoya/omniauth-apple/pull/111). Use the branch:

```diff
- gem 'omniauth-apple'
+ gem 'omniauth-apple', github: 'bvogel/omniauth-apple', branch: 'fix/apple-session-handling'
```

Next, add your credentials:

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :apple,
           Rails.application.credentials.dig(:apple, :service_id),
           '',
           {
             scope: 'email name',
             team_id: Rails.application.credentials.dig(:apple, :team_id),
             key_id: Rails.application.credentials.dig(:apple, :key_id),
             pem: Rails.application.credentials.dig(:apple, :pem),
             provider_ignores_state: true,
             nonce: :local
           }
end
```

Inside `credentials.yml` it can look more-less like this:

```yml
# credentials.yml
apple:
  service_id: serviceid
  client_id: com.example.omniauthable
  team_id: teamid
  key_id: keyid
  private_key: |
    -----BEGIN PRIVATE KEY-----
    foobarfoobarfoobarfoobarfoobar
    foobarfoobarfoobarfoobarfoobar
    foobarfoobarfoobarfoobarfoobar
    foobarfoobarfoobarfoobarfoobar
    -----END PRIVATE KEY-----"
```

Now when you click the "Sign in" button, everything should work and your app should receive a callback request to `sessions#create`. 

Here's my `SessionsController`.

`skip_before_action :verify_authenticity_token, only: :create` is required for the POST request from Apple.

Everything else is applicable for any other oAuth strategy.

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    @user = User.from_omniauth(request.env['omniauth.auth'])
    if @user.persisted?
      sign_in(@user)

      redirect_path = request.env['omniauth.origin'] || user_path(@user)
      redirect_to redirect_path, notice: t('sessions.success', name: @user.name)
    else
      redirect_to root_url, alert: t('sessions.failure')
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: t('sessions.destroy')
  end

  def failure
    redirect_to root_path, alert: t('sessions.failure')
  end

  private

  def sign_in(user)
    Current.user = user
    reset_session
    cookies.encrypted.permanent[:user_id] = user.id
  end

  def sign_out
    Current.user = nil
    reset_session
    cookies.delete(:user_id)
  end
end
```

You can see how I implemented the `from_omniauth` method [here]({% post_url 2023-01-09-omniauth-without-devise %}).

🤠 That's it! You can try to see how "Sign in with Apple" works on [this website](https://superails.com).
