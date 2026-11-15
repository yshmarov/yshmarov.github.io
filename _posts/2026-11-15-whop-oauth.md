---
layout: post
title: "Sign in with Whop in a Rails app"
author: Yaroslav Shmarov
tags: rails oauth omniauth whop devise
---

I built [omniauth-whop](https://github.com/yshmarov/omniauth-whop) to add **Sign in with Whop** to Ruby and Rails apps.

<a href="https://whop.com/start/?code=CAKARK" rel="sponsored nofollow">Get started with Whop</a>. *I may earn a commission.*

It handles OAuth, PKCE, and OpenID Connect token validation. Your app gets a verified Whop user ID and profile through the usual OmniAuth auth hash.

I tested it with real sandbox and production logins. Here's how to use it.

### 1. Create a Whop app

Start in the [Whop sandbox](https://sandbox.whop.com/). Open your business, then **Developer → Apps**.

Create an app called something like `My Ruby App`. Btw, Whop rejects app names containing `whop`!

In **OAuth**, use **Confidential** mode and register your callback:

```text
http://localhost:3000/auth/whop/callback
```

Copy the **Client ID** and **Client secret** into your app's environment as `WHOP_CLIENT_ID` and `WHOP_CLIENT_SECRET`. Set `WHOP_SANDBOX=true` for sandbox credentials.

One easy-to-miss step: under **Permissions**, add `oauth:token_exchange`, give it a short explanation, and save. This allows the client secret to exchange authorization codes. It is separate from the `openid profile email` scopes shown during login. See [Whop's authentication guide](https://whop.com/blog/add-user-authentication/).

### 2. Install the gems

```ruby
# Gemfile
gem "omniauth-whop"
gem "omniauth-rails_csrf_protection"
```

```sh
bundle install
```

The gem requires Ruby 3.2+. You don't need the Whop SDK.

### 3. Configure OmniAuth

For Rails without Devise:

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :whop,
           ENV.fetch("WHOP_CLIENT_ID"),
           ENV.fetch("WHOP_CLIENT_SECRET"),
           sandbox: ENV["WHOP_SANDBOX"] == "true"
end
```

Add the callback and failure routes:

```ruby
# config/routes.rb
get "/auth/whop/callback", to: "sessions#create"
get "/auth/failure", to: "sessions#failure"
```

Use a POST button to start login:

```erb
<%= button_to "Sign in with Whop", "/auth/whop", data: { turbo: false } %>
```

The button includes Rails' CSRF token. Whop redirects back with a GET callback. Keep CSRF protection, OAuth state validation, and PKCE enabled.

### 4. Find the user and start a session

For a small app that does not have authentication yet, a user can be identified by `provider` and `uid`:

```sh
bin/rails generate model User provider:string uid:string
```

Before running the migration, make those columns non-null and add a unique index:

```ruby
# Inside the generated migration's change method
create_table :users do |t|
  t.string :provider, null: false
  t.string :uid, null: false
  t.timestamps
end

add_index :users, [:provider, :uid], unique: true
```

```sh
bin/rails db:migrate
```

Read the verified identity from `request.env["omniauth.auth"]`:

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    auth = request.env.fetch("omniauth.auth")
    user = User.find_or_create_by!(provider: auth.provider, uid: auth.uid)

    reset_session
    session[:user_id] = user.id
    redirect_to root_path
  end

  def failure
    redirect_to root_path, alert: "Could not sign in with Whop. Please try again."
  end
end
```

Your app can now look up `User.find_by(id: session[:user_id])` on subsequent requests. This example assumes you have a root page. If you already use Devise, Rails' authentication generator, or another login system, use that system's session creation method instead.

**Use the Whop user ID, not email, as the external identity.** Profile fields can be absent. Linking Whop to an existing account should be an explicit flow for a signed-in user, rather than automatically matching an email address.

### Using Devise?

Configure the provider in Devise instead of adding the standalone OmniAuth middleware:

```ruby
# Inside Devise.setup in config/initializers/devise.rb
config.omniauth :whop,
                ENV.fetch("WHOP_CLIENT_ID"),
                ENV.fetch("WHOP_CLIENT_SECRET"),
                sandbox: ENV["WHOP_SANDBOX"] == "true"
```

Add `:omniauthable, omniauth_providers: [:whop]` to your existing `devise` declaration. Register a callbacks controller:

```ruby
# config/routes.rb
devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
```

Implement its `whop` action using the verified auth hash, your account-creation/linking rules, and Devise's `sign_in_and_redirect`. Existing Devise models may require email or password fields, so adapt those rules to your app rather than copying the minimal user model above.

The Devise callback URL is different. Register this exact URL in Whop:

```text
http://localhost:3000/users/auth/whop/callback
```

```erb
<%= button_to "Sign in with Whop", user_whop_omniauth_authorize_path,
              data: { turbo: false } %>
```

Keep `omniauth-rails_csrf_protection` installed with Devise too.

### What is in the auth hash?

```ruby
auth.provider            # "whop"
auth.uid                 # "user_..."
auth.info.name           # may be absent
auth.info.nickname       # may be absent
auth.info.email          # may be absent
auth.info.email_verified # true, false, or absent
auth.info.image          # may be absent
```

The gem verifies the ID token's signature, issuer, audience, expiry, issued-at time, and nonce. It also checks that the UserInfo response belongs to that same user.

The auth hash also contains token credentials. Keep them out of logs and browser responses. You don't need to save access or refresh tokens just to maintain your app's login session.

### Production checklist

- Create a production Whop app and use its credentials.
- Register your exact HTTPS callback URL, including the Devise prefix if applicable.
- Remove `WHOP_SANDBOX=true`. Pass a Ruby boolean to the `sandbox` option.
- Restrict your app's accepted hosts and configure your public URL correctly behind a proxy.
- Test a full login and an unsuccessful login before making the button available to users.

If code exchange fails, check `oauth:token_exchange`, the client secret, and whether the credentials match the selected environment. For a redirect error, compare the registered callback URL character by character.

You can also try the [standalone Rack demo](https://github.com/yshmarov/omniauth-whop#run-the-sandbox-demo) before integrating it into your app.

Whop login tells you **who the user is**. It does not prove they bought a product or have an active membership. Handle that separately; for payments, see [pay-whop](https://github.com/yshmarov/pay-whop).
