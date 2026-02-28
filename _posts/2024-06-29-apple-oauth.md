---
layout: post
title: "Sign in with Apple in a Rails app"
author: Yaroslav Shmarov
tags: oauth apple ios omniauth
thumbnail: /assets/thumbnails/apple-logo.png
youtube_id: __d_15rP16M
---

### Get Apple API keys

First of all, you need to [create an Apple Developer account](https://developer.apple.com/programs/enroll/). It costs $99/year. Greedy bastards!

1. [Create an app ID](https://developer.apple.com/account/resources/identifiers/bundleId/add/bundle). Check "Sign in with Apple"; no need to click "Edit". `Identifier` can be anything, but normally the reverse of your domain like `com.superails`.

2. [Create a service ID](https://developer.apple.com/account/resources/identifiers/serviceId/add/). `Identifier` can be anything, but normally the reverse of your domain like `com.superails.auth`. Check "Sign in with Apple"; click "Configure".

![Apple oAuth callback urls](/assets/images/apple-auth-callback-urls.png)

You will now have access to these oAuth credentials:

![apple-auth-service](/assets/images/apple-auth-service.png)

Add your callback URLs. Apple OAuth works on `localhost` -- add `http://localhost:3000/auth/apple/callback` for development alongside your production URL.

3. [Create a key ID](https://developer.apple.com/account/resources/authkeys/add). Check "Sign in with Apple". You will be able to download the `pem` secret key.

![apple-auth-key](/assets/images/apple-auth-key.png)

### OAuth in your Rails app

Install the gem [omniauth-apple](https://github.com/nhosoya/omniauth-apple)

```ruby
# Gemfile
gem "omniauth-apple"
```

You do **not** need `omniauth-rails_csrf_protection`. OmniAuth 2.x has built-in CSRF protection -- just configure it in the initializer:

```ruby
OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
```

Add callback routes. **Apple login goes via POST, not GET**, so you need both:

```ruby
# config/routes.rb
get "/auth/:provider/callback", to: "sessions#create"
post "/auth/:provider/callback", to: "sessions#create"
```

Using `:provider` as a wildcard means you don't need a new route for each OAuth provider.

```ruby
button_to "Login with Apple", "/auth/apple"
```

### Why Apple OAuth needs special handling

Apple uses `response_mode: form_post` -- after authentication, Apple redirects the user's browser to **POST** to your callback URL. This cross-site POST from `appleid.apple.com` causes two problems:

1. **Session cookies are not sent.** Browsers enforce `SameSite=Lax` by default, which blocks cookies on cross-site POST requests. This means any values stored in the session during the request phase (state, nonce) are unavailable during the callback.
2. **Rails CSRF protection rejects the request.** Rails checks the `Origin` header and sees `https://appleid.apple.com` instead of your domain, raising `ActionController::InvalidAuthenticityToken`.

### Configuration

You need three things to handle this:

1. **`provider_ignores_state: true`** -- skips the state parameter comparison (which would fail because the session-stored state is lost).
2. **Skip nonce verification** -- the nonce is also stored in the session and lost on callback. Override `verify_nonce!` to skip it. The `id_token` is still verified by JWK signature, audience, issuer, and expiration claims.
3. **`skip_before_action :verify_authenticity_token`** -- skip Rails CSRF check for the callback action.

```ruby
# config/initializers/omniauth.rb
require "omniauth-apple"

# OmniAuth 2.x built-in CSRF protection — no extra gem needed
OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)

# Apple's form_post response_mode sends a cross-site POST that does not carry
# session cookies (SameSite=Lax), so the session-stored nonce is lost.
# Skip nonce verification — the id_token is still verified by signature,
# audience, issuer, and expiration claims.
OmniAuth::Strategies::Apple.class_eval do
  private

  def verify_nonce!(_id_token) = nil
end

Rails.application.config.middleware.use OmniAuth::Builder do
  # Only register Apple if credentials are configured.
  # This lets team members without Apple dev accounts skip this provider.
  if Rails.application.credentials.dig(:apple, :client_id).present? &&
     Rails.application.credentials.dig(:apple, :team_id).present? &&
     Rails.application.credentials.dig(:apple, :key_id).present? &&
     Rails.application.credentials.dig(:apple, :pem).present?
    provider :apple,
             Rails.application.credentials.dig(:apple, :client_id),
             "",
             scope: "email name",
             team_id: Rails.application.credentials.dig(:apple, :team_id),
             key_id: Rails.application.credentials.dig(:apple, :key_id),
             pem: Rails.application.credentials.dig(:apple, :pem),
             authorized_client_ids: [Rails.application.credentials.dig(:apple, :client_id)],
             provider_ignores_state: true
  end
end
```

Inside `credentials.yml` it can look more-less like this:

```yml
# credentials.yml
apple:
  client_id: com.example.auth
  team_id: teamid
  key_id: keyid
  pem: |
    -----BEGIN PRIVATE KEY-----
    foobarfoobarfoobarfoobarfoobar
    foobarfoobarfoobarfoobarfoobar
    foobarfoobarfoobarfoobarfoobar
    foobarfoobarfoobarfoobarfoobar
    -----END PRIVATE KEY-----
```

The `client_id` is your **Services ID** (e.g. `com.example.auth`), not the App ID. The `pem` must be a YAML multiline string (use `|`) with real newlines -- not escaped `\n`.

Now when you click the "Sign in" button, everything should work and your app should receive a callback request to `sessions#create`.

Here's my `SessionsController`.

`skip_before_action :verify_authenticity_token, only: :create` is required because Apple's cross-site POST carries `Origin: https://appleid.apple.com`, which Rails rejects.

Everything else is applicable for any other OAuth strategy.

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      sign_in(@user)

      redirect_path = request.env["omniauth.origin"] || user_path(@user)
      redirect_to redirect_path, notice: t("sessions.success", name: @user.name)
    else
      redirect_to root_url, alert: t("sessions.failure")
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: t("sessions.destroy")
  end

  def failure
    redirect_to root_path, alert: t("sessions.failure")
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

### Common errors and what causes them

| Error | Cause |
|---|---|
| `undefined method 'bytesize' for nil` | Missing `provider_ignores_state: true`. The `omniauth-oauth2` gem calls `secure_compare` on the session state, which is `nil` because session cookies are not sent with Apple's cross-site POST. |
| `invalid_credentials` | Nonce verification failing. The nonce is stored in the session during the request phase but lost during Apple's POST callback. Fix by overriding `verify_nonce!`. |
| `ActionController::InvalidAuthenticityToken` | Rails CSRF protection rejects the POST because `Origin: https://appleid.apple.com` doesn't match your domain. Fix with `skip_before_action :verify_authenticity_token`. |

### Hotwire Native (iOS)

If you're wrapping your Rails app in a Hotwire Native iOS shell, Apple OAuth needs additional handling -- WKWebView's embedded user agent is blocked by Apple. See [OAuth in Hotwire Native iOS apps]({% post_url 2026-02-28-hotwire-native-oauth %}) for the full solution using `ASWebAuthenticationSession`.

That's it! You can try to see how "Sign in with Apple" works on [this website](https://superails.com).
