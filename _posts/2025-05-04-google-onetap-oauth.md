---
layout: post
title: Google One Tap Authentication with Rails 8 and Devise
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

### 2. Google One Tap popup

First, allow JS origins for development & production in the [Google API Dashboard](https://console.cloud.google.com/apis/dashboard)

![google-one-touch-authorize](/assets/images/google-one-touch-authorize.png)

In your OAuth Client ID settings, add:
- **Authorized JavaScript origins**: `http://localhost:3000`, `https://yourdomain.com`
- **Authorized redirect URIs**: `http://localhost:3000/google_onetap_callback`, `https://yourdomain.com/google_onetap_callback`

⚠️ Changes in Google Cloud Console can take **5-30 minutes** to propagate. If you see `The given origin is not allowed for the given client ID` in the browser console, wait and retry.

```diff
# config/routes.rb
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [ :sessions, :registrations ]
   devise_scope :user do
    delete "/users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
+     post "/google_onetap_callback", to: "users/omniauth_callbacks#google_onetap", as: :google_onetap_callback
   end
```

The One Tap partial. Render it on pages where you want the prompt (e.g. homepage):

```html
<!-- app/views/shared/_google_onetap.html.erb -->
<% if Rails.application.credentials.dig(:google_oauth2, :key).present? && !user_signed_in? %>
  <script src="https://accounts.google.com/gsi/client" async defer></script>
  <div
    id="g_id_onload"
    data-client_id="<%= Rails.application.credentials.dig(:google_oauth2, :key) %>"
    data-login_uri="<%= google_onetap_callback_url %>"
    data-itp_support="true"
    data-context="signin"
  ></div>
<% end %>
```

Google POSTs a signed JWT to your callback. You need to verify it. Use the `jwt` gem (not `googleauth`, which has OpenSSL 3.x CRL issues on macOS):

```ruby
# Gemfile
gem "jwt"
```

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_onetap

  def google_onetap
    unless g_csrf_token_valid?
      redirect_to root_path, alert: "Failure. Please try again"
      return
    end

    payload = verify_google_id_token(params[:credential])
    user = User.from_google_onetap(payload)

    if user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Google"
      sign_in_and_redirect user, event: :authentication
    else
      redirect_to root_path, alert: user.errors.full_messages.join("\n")
    end
  rescue JWT::DecodeError
    redirect_to root_path, alert: "Failure. Please try again"
  end

  private

  GOOGLE_CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs"
  GOOGLE_ISSUERS = %w[accounts.google.com https://accounts.google.com].freeze

  def g_csrf_token_valid?
    token = cookies["g_csrf_token"]
    token.present? && token == params["g_csrf_token"]
  end

  def verify_google_id_token(token)
    jwks = fetch_google_jwks
    client_id = Rails.application.credentials.dig(:google_oauth2, :key)

    payload, = JWT.decode(token, nil, true, {
      algorithms: ["RS256"],
      jwks: jwks,
      iss: GOOGLE_ISSUERS,
      verify_iss: true,
      aud: client_id,
      verify_aud: true
    })

    payload
  end

  def fetch_google_jwks
    Rails.cache.fetch("google_jwks", expires_in: 1.hour) do
      uri = URI(GOOGLE_CERTS_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5
      response = http.get(uri.path)
      JSON.parse(response.body)
    end
  end
end
```

The One Tap payload is different from the classic OAuth payload:

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

### Gotchas

- **`skip_before_action :verify_authenticity_token`** is required for the `google_onetap` action because Google POSTs from their domain. Google's own CSRF token (`g_csrf_token`) is validated instead.
- **Content blocker errors** in console (`/gsi/log` blocked) are harmless — just Google's telemetry being blocked by ad blockers.
- **OpenSSL 3.x CRL errors on macOS**: If you hit `certificate verify failed (unable to get certificate CRL)` when fetching Google's JWKS, set `cert_store.flags = 0` on the `Net::HTTP` connection to disable CRL checking while still verifying the cert chain.

Inspired by [patrickkarsh's post](https://patrickkarsh.medium.com/how-to-add-google-one-touch-authentication-to-a-ruby-on-rails-application-6ac8776c4190).
