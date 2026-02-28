---
layout: post
title: "OAuth in Hotwire Native iOS apps with ASWebAuthenticationSession"
author: Yaroslav Shmarov
tags: hotwire-native rails oauth ios swift
thumbnail: /assets/thumbnails/turbo.png
---

Google and Apple block OAuth from embedded web views (WKWebView) with `disallowed_useragent`. This guide shows how to make OAuth work in a Hotwire Native iOS app using `ASWebAuthenticationSession` -- Apple's purpose-built API for OAuth -- with a path configuration rule and token handoff.

The approach uses zero bridge components. It works with any OmniAuth provider (Google, Apple, Facebook, etc.) and extends to social account linking (YouTube, TikTok, etc.) where the user is already signed in.

## How it works

```
WKWebView          ASWebAuthenticationSession       Rails           Provider
    │                          │                      │                │
 1. User taps                  │                      │                │
    "Sign in with Google"      │                      │                │
    │                          │                      │                │
 2. Turbo navigates to         │                      │                │
    /auth/native/google        │                      │                │
    │                          │                      │                │
 3. Path config matches        │                      │                │
    ^/auth/ → "safari"         │                      │                │
    TabBarController rejects   │                      │                │
    proposal, starts           │                      │                │
    ASWebAuthSession ─────────►│                      │                │
    │                          │                      │                │
    │                     4. Loads GET                 │                │
    │                        /auth/native/google ────►│                │
    │                          │                      │                │
    │                     5. Trampoline page           │                │
    │                        auto-submits POST        │                │
    │                        /auth/google_oauth2 ────►│                │
    │                          │                      │                │
    │                          │                 6. OmniAuth            │
    │                          │                    redirects ────────►│
    │                          │                      │                │
    │                          │                      │     7. User    │
    │                          │                      │     signs in   │
    │                          │                      │                │
    │                          │                 8. Callback ◄─────────┤
    │                          │                    /auth/google/      │
    │                          │                    callback           │
    │                          │                      │                │
    │                          │                 9. Detect native      │
    │                          │                    request, generate  │
    │                          │                    token, redirect    │
    │                          │  ◄── yourapp://callback?token=TOKEN   │
    │                          │                      │                │
    │                    10. Completion handler        │                │
    │                        fires with callback URL  │                │
    │  ◄── navigate to        │                      │                │
    │      /hotwire_native/    │                      │                │
    │      sign_in?token=TOKEN │                      │                │
    │                          │                      │                │
 11. Rails validates token, ─────────────────────────►│                │
     signs in user,                                   │                │
     sets session cookie                              │                │
     in WKWebView,                                    │                │
     redirects to /reset_app                          │                │
```

Key insight: `ASWebAuthenticationSession` has its own cookie store separate from WKWebView. The user authenticates in the system browser, Rails generates a short-lived token, redirects to a custom URL scheme, and the iOS app hands that token to WKWebView to establish the session.

## Rails changes

### 1. Token generator on User model

Rails 7.1+ has built-in single-use, purpose-scoped tokens:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  generates_token_for :native_oauth, expires_in: 2.minutes
end
```

### 2. Trampoline controller

OmniAuth requires a POST request (CSRF protection). `ASWebAuthenticationSession` can only open GET URLs. The trampoline bridges this gap -- it's a GET page that auto-submits a POST form.

The controller also sets backup cookies for the native detection and user token. These are `SameSite=None` because Apple Sign In uses `response_mode=form_post` -- a cross-origin POST that drops `SameSite=Lax` session cookies.

```ruby
# app/controllers/hotwire_native/oauth_controller.rb
class HotwireNative::OauthController < ApplicationController
  skip_before_action :authenticate_user!
  layout false

  def start
    session[:native_oauth] = true
    cookies[:native_oauth] = {
      value: "1", expires: 5.minutes.from_now,
      same_site: :none, secure: true
    }
    @provider = params[:provider]
    @user_token = params[:user_token]
    return if @user_token.blank?

    # Signed cookie backup for social linking — survives cross-origin POST
    cookies.signed[:native_oauth_user_token] = {
      value: @user_token, expires: 5.minutes.from_now,
      same_site: :none, secure: true
    }
  end
end
```

```erb
<!-- app/views/hotwire_native/oauth/start.html.erb -->
<!DOCTYPE html>
<html>
<body>
  <p>Redirecting...</p>
  <%%= form_tag "/auth/#{@provider}", method: :post, id: "oauth-trampoline" do %>
    <input type="hidden" name="native" value="ios">
    <%% if @user_token.present? %>
      <input type="hidden" name="user_token" value="<%%= @user_token %>">
    <%% end %>
    <noscript><button type="submit">Continue to sign in</button></noscript>
  <%% end %>
  <%%= javascript_tag nonce: true do %>
    document.getElementById("oauth-trampoline").submit();
  <%% end %>
</body>
</html>
```

### 3. Token sign-in controller

Validates the token inside WKWebView and establishes the session:

```ruby
# app/controllers/hotwire_native/sign_in_controller.rb
class HotwireNative::SignInController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_onboarding

  def show
    user = User.find_by_token_for(:native_oauth, params[:token])

    unless user
      redirect_to new_user_session_path, alert: I18n.t("devise.omniauth_callbacks.failure")
      return
    end

    sign_in(user)
    redirect_to "/reset_app"
  end
end
```

`skip_before_action :require_onboarding` is essential -- without it, a new user would be redirected to onboarding before the session is established, breaking the token handoff.

### 4. Routes

```ruby
# config/routes/hotwire_native.rb
namespace :hotwire_native do
  get "sign_in", to: "sign_in#show"
end

# Outside the namespace — the URL must start with /auth/ for the path config rule
get "auth/native/:provider", to: "hotwire_native/oauth#start", as: :native_oauth_start
```

### 5. OmniAuth callback -- native branch

In your OmniAuth callback controller, detect native requests and redirect to the custom URL scheme instead of signing in directly:

```ruby
NATIVE_URL_SCHEME = "yourapp" # or read from config

def handle_auth_provider(kind, auth_payload)
  if native_oauth_request?
    user = User.from_omniauth(auth_payload) # Your existing find-or-create logic
    if user.persisted?
      token = user.generate_token_for(:native_oauth)
      redirect_to "#{NATIVE_URL_SCHEME}://callback?token=#{token}",
                  allow_other_host: true
    else
      redirect_to new_user_registration_url, alert: user.errors.full_messages.join("\n")
    end
    return
  end

  # ... existing web sign-in flow
end

private

# Three detection paths are needed because OAuth callbacks arrive differently:
# 1. omniauth.params "native" — GET-based providers that preserve query params (e.g. Google)
# 2. session[:native_oauth]    — set on the trampoline page before the POST to OmniAuth
# 3. SameSite=None cookie      — survives Apple's cross-origin POST callback where
#                                  the session cookie (SameSite=Lax) is dropped
def native_oauth_request?
  request.env.dig("omniauth.params", "native") == "ios" ||
    session.delete(:native_oauth) ||
    cookies.delete(:native_oauth) == "1"
end
```

### 6. OAuth button helper

Instead of inlining the native/web branching in every view, use a helper:

```ruby
# app/helpers/application_helper.rb
def oauth_button(provider, **options, &)
  if hotwire_native_app?
    token = user_signed_in? ? current_user.generate_token_for(:native_oauth) : nil
    path_params = token ? { user_token: token } : {}
    link_to(native_oauth_start_path(provider, **path_params),
            class: options[:class],
            data: { turbo_frame: "_top" },
            &)
  else
    button_to("/auth/#{provider}",
              class: options[:class],
              data: { turbo: false },
              &)
  end
end
```

Native renders a `link_to` (so Turbo intercepts navigation and the path config routes to ASWebAuthenticationSession). Web renders a `button_to` (POST form for OmniAuth). When the user is signed in, a `user_token` is automatically included for social account linking.

Usage in views:

```erb
<%%= oauth_button(:google_oauth2, class: "btn") do %>
  Sign in with Google
<%% end %>
```

## iOS changes

### 1. Register URL scheme in Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.yourapp.oauth</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>yourapp</string>
    </array>
  </dict>
</array>
```

### 2. Path configuration rule

Add this rule to your path configuration (both local JSON and server-driven). It must come before any catch-all rules:

```json
{
  "patterns": ["^/auth/"],
  "properties": {
    "view_controller": "safari"
  }
}
```

### 3. Endpoint constants

```swift
// Endpoint.swift (or wherever you keep URL constants)
extension Endpoint {
    enum OAuth {
        static let callbackScheme = "yourapp"
        static let nativeSignInURL = rootURL.appending(path: "hotwire_native/sign_in")
    }
}
```

### 4. TabBarController (or your NavigatorDelegate)

This is the core iOS change. In `handle(proposal:)`, intercept the `"safari"` view controller identifier and start an `ASWebAuthenticationSession`:

```swift
import AuthenticationServices

class TabBarController: UITabBarController {
    private var authSession: ASWebAuthenticationSession?

    // ... existing code ...
}

// MARK: - NavigatorDelegate
extension TabBarController: NavigatorDelegate {
    func handle(proposal: VisitProposal, from navigator: Navigator) -> ProposalResult {
        switch proposal.viewController {
        case "safari":
            startOAuthSession(url: proposal.url)
            return .reject  // WKWebView never navigates — no frozen state
        default:
            return .accept
        }
    }
}

// MARK: - OAuth
extension TabBarController {
    private func startOAuthSession(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        // Append native=ios so Rails redirects to the custom URL scheme
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "native", value: "ios"))
        components.queryItems = queryItems

        guard let oauthURL = components.url else { return }

        let session = ASWebAuthenticationSession(
            url: oauthURL,
            callbackURLScheme: Endpoint.OAuth.callbackScheme
        ) { [weak self] callbackURL, error in
            guard let self else { return }

            if let error {
                self.authSession = nil
                return
            }

            guard let callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                self.authSession = nil
                return
            }

            let queryItems = components.queryItems ?? []

            if let token = queryItems.first(where: { $0.name == "token" })?.value {
                // Auth sign-in: hand off token to WKWebView
                Task { @MainActor in
                    self.completeOAuthSignIn(token: token)
                    self.authSession = nil
                }
            } else {
                // Social linking: account linked server-side, just reload
                Task { @MainActor in
                    self.activeNavigator?.reload()
                    self.authSession = nil
                }
            }
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false  // Share Safari cookies for SSO
        session.start()
        authSession = session  // Strong reference to prevent deallocation
    }

    private func completeOAuthSignIn(token: String) {
        guard var components = URLComponents(
            url: Endpoint.OAuth.nativeSignInURL, resolvingAgainstBaseURL: false
        ) else { return }

        components.queryItems = [URLQueryItem(name: "token", value: token)]

        guard let signInURL = components.url else { return }

        // Navigate WKWebView to the token sign-in endpoint.
        // This sets the session cookie inside WKWebView.
        activeNavigator?.route(signInURL)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension TabBarController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}
```

## Why ASWebAuthenticationSession over SFSafariViewController

| | ASWebAuthenticationSession | SFSafariViewController |
|---|---|---|
| **Purpose** | Built for OAuth | General web browsing |
| **Cookie sharing** | Shares Safari cookies (SSO) | Isolated cookie store |
| **Callback** | Built-in completion handler | Requires NotificationCenter relay |
| **Bridge component** | Not needed (path config only) | Needs bridge component (JS + Swift) |
| **Apple recommendation** | Yes, for authentication | No, not for auth |

## Extending to social account linking

When linking social accounts (YouTube, TikTok, etc.), the user is already signed in to WKWebView but `ASWebAuthenticationSession` has a separate cookie store. The `oauth_button` helper handles this automatically -- it generates a `user_token` when the user is signed in and passes it through the trampoline.

In the OmniAuth callback, look up the user via the token (with a cookie fallback for Apple's cross-origin POST):

```ruby
def handle_social_provider(kind, auth_payload)
  if native_oauth_request?
    # Try omniauth params first, fall back to signed cookie backup
    user_token = request.env.dig("omniauth.params", "user_token") || cookies.signed[:native_oauth_user_token]
    cookies.delete(:native_oauth_user_token)
    user = User.find_by_token_for(:native_oauth, user_token) if user_token.present?
    unless user
      redirect_to "#{NATIVE_URL_SCHEME}://callback?error=unauthenticated", allow_other_host: true
      return
    end

    social_account = SocialAccount.create_or_update_from_omniauth(auth_payload, user)
    if social_account.persisted?
      redirect_to "#{NATIVE_URL_SCHEME}://callback?social=linked", allow_other_host: true
    else
      redirect_to "#{NATIVE_URL_SCHEME}://callback?error=link_failed", allow_other_host: true
    end
    return
  end

  # ... existing web flow
end
```

On iOS, the `ASWebAuthenticationSession` completion handler already branches on whether a `token` is present (auth sign-in) or not (social linking -- just reload the page).

## Apple Sign In gotcha: SameSite cookies

Apple Sign In uses `response_mode=form_post` -- Apple's servers POST the callback to your app. This is a cross-origin POST, which causes browsers to drop `SameSite=Lax` cookies (the Rails default). Both `session[:native_oauth]` and `session` itself get lost.

The fix: the trampoline controller sets `SameSite=None` cookies as backups:
- `cookies[:native_oauth]` -- detects native OAuth requests when the session is lost
- `cookies.signed[:native_oauth_user_token]` -- preserves the user token for social linking

The `native_oauth_request?` method checks three sources:

1. `omniauth.params["native"]` -- works for most providers (GET callback)
2. `session[:native_oauth]` -- works when the session cookie survives
3. `cookies[:native_oauth]` -- `SameSite=None` backup for Apple's cross-origin POST
