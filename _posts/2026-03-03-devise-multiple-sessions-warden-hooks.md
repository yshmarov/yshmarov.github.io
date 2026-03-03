---
layout: post
title: "Devise has_many :sessions - track, list, and revoke active sessions"
author: Yaroslav Shmarov
tags: ruby-on-rails devise warden authentication sessions security
thumbnail: /assets/thumbnails/devise.png
---

Track every browser session for a Devise-authenticated user, display them in "your active sessions" UI, and let users revoke sessions remotely. When a session is revoked, the next request from that browser forces a sign-out.

This approach hooks into Warden (the authentication layer underneath Devise) so it works with **all** sign-in methods: standard email/password, magic links, OmniAuth, `sign_in(user)` — everything.

## Architecture overview

```
Sign in → Warden fires :set_user → SessionManager.on_sign_in → Session.track!
Request → Warden fires :fetch    → SessionManager.on_fetch   → touch_last_active! / force sign-out if revoked
Sign out → Warden fires logout   → SessionManager.on_logout  → Session#revoke!
```

Every browser gets a UUID stored in the encrypted session cookie. That UUID maps to a `Session` database record. On each request, Warden's `:fetch` event checks the record — if it's been revoked (from another device), the user is force-signed-out.

## 1. Migration

```ruby
# db/migrate/20260301000000_create_sessions.rb
class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :session_id, null: false
      t.string :ip_address
      t.string :user_agent, limit: 1024
      t.string :browser_name
      t.string :os_name
      t.string :device_type
      t.datetime :last_active_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, [:user_id, :revoked_at]
  end
end
```

Key details:
- `session_id` has a **unique index** — this is critical for the race condition handling in `track!`.
- `revoked_at` is a soft-delete timestamp. We don't hard-delete sessions because we need them for the "active sessions" UI and for detecting revoked cookies.
- `user_agent` is capped at 1024 characters because user agents can be absurdly long.

Run the migration:

```bash
bin/rails db:migrate
```

## 2. Session model

Add the `browser` gem for user-agent parsing:

```ruby
# Gemfile
gem "browser", "~> 6.0"
```

```bash
bundle install
```

```ruby
# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(revoked_at: nil) }

  before_create :parse_user_agent

  # Find-or-create a session record for a given session_id.
  # Handles race conditions from concurrent requests.
  def self.track!(user:, session_id:, request:)
    find_or_create_by!(session_id: session_id) do |session|
      session.user = user
      session.ip_address = request.remote_ip
      session.user_agent = request.user_agent&.first(1024)
      session.last_active_at = Time.current
    end
  rescue ActiveRecord::RecordNotUnique
    retries ||= 0
    retry if (retries += 1) < 3
    raise
  end

  # Soft-revoke the session. Does NOT delete the record.
  def revoke!
    update!(revoked_at: Time.current)
  end

  # Update last_active_at, but only if 5+ minutes have passed.
  # Avoids a DB write on every single request.
  def touch_last_active!
    return if last_active_at > 5.minutes.ago

    update_column(:last_active_at, Time.current)
  end

  private

  def parse_user_agent
    return if user_agent.blank?

    client = Browser.new(user_agent)
    self.browser_name = client.name
    self.os_name = client.platform.name
    self.device_type = if client.device.mobile?
      "Mobile"
    elsif client.device.tablet?
      "Tablet"
    else
      "Desktop"
    end
  end
end
```

Why `find_or_create_by!` + `rescue RecordNotUnique`? Because `find_or_create_by!` is not atomic. Two concurrent requests can both fail the SELECT, then both attempt INSERT. The unique index on `session_id` causes one to fail. We rescue and retry — the second attempt will find the existing record.

## 3. User model association

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :sessions, dependent: :destroy
end
```

## 4. SessionManager

This module contains the three lifecycle methods called from Warden hooks. Keeping them in a separate module makes them independently testable.

```ruby
# app/lib/session_manager.rb
module SessionManager
  # Called on sign-in (Warden :set_user or :authentication events).
  # Generates a session_id UUID and creates the Session record.
  def self.on_sign_in(user:, warden:, scope:)
    session_id = warden.session(scope)["session_id"] ||= SecureRandom.uuid
    Session.track!(
      user: user,
      session_id: session_id,
      request: ActionDispatch::Request.new(warden.env)
    )
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[SessionManager] on_sign_in failed: #{e.message}")
  end

  # Called on every authenticated request (Warden :fetch event).
  # Checks for revocation, updates last_active_at, or lazy-creates a missing record.
  def self.on_fetch(user:, warden:, scope:)
    session_id = warden.session(scope)["session_id"]
    return unless session_id

    session_record = Session.find_by(session_id: session_id)

    if session_record&.revoked_at?
      force_sign_out(warden: warden, scope: scope)
    elsif session_record
      session_record.touch_last_active!
    else
      # Lazy-create: session_id exists in cookie but DB record is missing
      Session.track!(
        user: user,
        session_id: session_id,
        request: ActionDispatch::Request.new(warden.env)
      )
    end
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[SessionManager] on_fetch failed: #{e.message}")
  end

  # Called on sign-out (Warden before_logout hook).
  # Soft-revokes the session record.
  def self.on_logout(warden:, scope:)
    # Skip if this logout was triggered by our own force_sign_out
    # (the session is already revoked in that case)
    return if warden.env["app.revoking_session"]

    session_id = warden.session(scope)&.dig("session_id")
    return unless session_id

    Session.find_by(session_id: session_id)&.revoke!
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[SessionManager] on_logout failed: #{e.message}")
  end

  # Force sign-out for a revoked session. Sets a flag to prevent
  # the before_logout hook from double-revoking.
  def self.force_sign_out(warden:, scope:)
    warden.env["app.revoking_session"] = true
    proxy = Devise::Hooks::Proxy.new(warden)
    proxy.sign_out(scope)
    throw :warden, scope: scope, message: :revoked_session
  end
  private_class_method :force_sign_out
end
```

### Important: `ActionDispatch::Request` vs `Rack::Request`

Warden hooks receive a `Warden::Proxy` (`warden`). `warden.request` returns a **`Rack::Request`**, which does NOT have the `remote_ip` method. `remote_ip` is an `ActionDispatch::Request` method. You must wrap the env:

```ruby
# CORRECT — ActionDispatch::Request has #remote_ip
request = ActionDispatch::Request.new(warden.env)
request.remote_ip # => "192.168.1.1"

# WRONG — Rack::Request does NOT have #remote_ip
warden.request.remote_ip # => NoMethodError
```

### The `app.revoking_session` flag

When a revoked session is detected on `:fetch`, we call `proxy.sign_out(scope)` which triggers the `before_logout` hook. Without the flag, `on_logout` would try to `revoke!` a session that's already revoked. The flag skips that:

```
:fetch detects revoked session
  → sets warden.env["app.revoking_session"] = true
  → calls proxy.sign_out(:user)
    → before_logout hook fires
      → on_logout checks flag → skips revoke (already done)
  → throw :warden redirects to sign-in
```

## 5. Warden hooks initializer

```ruby
# config/initializers/warden_hooks.rb
Warden::Manager.after_set_user do |user, warden, opts|
  scope = opts[:scope]

  # Sign-in events: create a session record
  if scope == :user && [:set_user, :authentication].include?(opts[:event])
    SessionManager.on_sign_in(user: user, warden: warden, scope: scope)
  end

  # Fetch events (every authenticated request): check revocation, update activity
  if scope == :user && opts[:event] == :fetch
    SessionManager.on_fetch(user: user, warden: warden, scope: scope)
  end
end

Warden::Manager.before_logout do |_user, warden, opts|
  if opts[:scope] == :user
    SessionManager.on_logout(warden: warden, scope: opts[:scope])
  end
end
```

### Warden events reference

| Event | When | Our hook |
|---|---|---|
| `:set_user` | `Devise.sign_in(user)` or `warden.set_user(user)` | Creates `Session` |
| `:authentication` | `warden.authenticate!` (e.g. magic link strategies) | Creates `Session` |
| `:fetch` | Every request where Warden loads user from session cookie | `touch_last_active!`, lazy-create, or force sign-out |
| `before_logout` | `warden.logout(:user)` on any sign-out | Soft-revokes `Session` |

### Graceful degradation for existing sessions

Users who were signed in **before** this feature is deployed have no `session_id` in their session cookie. The `:fetch` hook guards on `return unless session_id` — when it's `nil`, all tracking is skipped. These users browse normally. They'll get a `Session` record on their next sign-in.

## 6. Revoked session Devise message

Add a flash message for the revoked session redirect:

```yaml
# config/locales/en/devise.en.yml
en:
  devise:
    failure:
      revoked_session: "Your session has been revoked. Please sign in again."
```

## 7. Sessions controller (optional — for "manage sessions" UI)

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sessions = current_user.sessions.active.order(last_active_at: :desc)
    @current_session_id = request.env["warden"].session(:user)["session_id"]
  end

  def destroy
    session_record = current_user.sessions.find(params[:id])
    session_record.revoke!
    redirect_to sessions_path, notice: "Session revoked."
  end
end
```

```erb
<%# app/views/sessions/index.html.erb %>
<h1>Your Active Sessions</h1>

<% @sessions.each do |session| %>
  <div style="border: 1px solid #ddd; padding: 1rem; margin-bottom: 1rem;">
    <p>
      <strong><%= session.browser_name %></strong> on <%= session.os_name %>
      (<%= session.device_type %>)
      <% if session.session_id == @current_session_id %>
        <span style="color: green;">(This device)</span>
      <% end %>
    </p>
    <p>IP: <%= session.ip_address %></p>
    <p>Last active: <%= time_ago_in_words(session.last_active_at) %> ago</p>

    <% unless session.session_id == @current_session_id %>
      <%= button_to "Revoke", session_path(session), method: :delete %>
    <% end %>
  </div>
<% end %>
```

```ruby
# config/routes.rb
resources :sessions, only: [:index, :destroy]
```

When a user clicks "Revoke" on a session, that session's `revoked_at` is set. The next time the revoked browser makes a request, the `:fetch` hook detects it and force-signs it out.

## 8. Tests

### Factory

```ruby
# test/factories/sessions.rb
FactoryBot.define do
  factory :session do
    association :user
    session_id { SecureRandom.uuid }
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }
    browser_name { "Chrome" }
    os_name { "macOS" }
    device_type { "Desktop" }
    last_active_at { Time.current }

    trait :mobile do
      user_agent { "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" }
      browser_name { "Safari" }
      os_name { "iOS" }
      device_type { "Mobile" }
    end

    trait :revoked do
      revoked_at { Time.current }
    end
  end
end
```

### Model tests

```ruby
# test/models/session_test.rb
require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test ".track! creates a new session record" do
    request = OpenStruct.new(remote_ip: "192.168.1.1", user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
    session_id = SecureRandom.uuid

    assert_difference "Session.count", 1 do
      session = Session.track!(user: @user, session_id: session_id, request: request)
      assert_equal @user, session.user
      assert_equal session_id, session.session_id
      assert_equal "192.168.1.1", session.ip_address
      assert_not_nil session.last_active_at
    end
  end

  test ".track! does not duplicate sessions with the same session_id" do
    request = OpenStruct.new(remote_ip: "192.168.1.1", user_agent: "Mozilla/5.0")
    session_id = SecureRandom.uuid

    Session.track!(user: @user, session_id: session_id, request: request)

    assert_no_difference "Session.count" do
      Session.track!(user: @user, session_id: session_id, request: request)
    end
  end

  test ".track! parses user agent on create" do
    request = OpenStruct.new(
      remote_ip: "10.0.0.1",
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    )

    session = Session.track!(user: @user, session_id: SecureRandom.uuid, request: request)

    assert_equal "Safari", session.browser_name
    assert_includes session.os_name, "iOS"
    assert_equal "Mobile", session.device_type
  end

  test "#revoke! sets revoked_at timestamp" do
    session = create(:session, user: @user)
    assert_nil session.revoked_at

    session.revoke!

    assert_not_nil session.reload.revoked_at
  end

  test "#touch_last_active! updates when stale (>5 minutes)" do
    session = create(:session, user: @user, last_active_at: 10.minutes.ago)
    original_time = session.last_active_at

    session.touch_last_active!

    assert session.reload.last_active_at > original_time
  end

  test "#touch_last_active! does NOT update when recent (<5 minutes)" do
    session = create(:session, user: @user, last_active_at: 2.minutes.ago)
    original_time = session.last_active_at

    session.touch_last_active!

    assert_equal original_time, session.reload.last_active_at
  end

  test ".active scope returns only non-revoked sessions" do
    active = create(:session, user: @user)
    _revoked = create(:session, :revoked, user: @user)

    results = @user.sessions.active
    assert_includes results, active
    assert_equal 1, results.count
  end
end
```

### Integration tests for Warden hooks

These tests verify the full sign-in/sign-out lifecycle end-to-end:

```ruby
# test/integration/warden_hooks_test.rb
require "test_helper"

class WardenHooksTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
  end

  test "sign-in creates a Session record" do
    assert_difference "Session.count", 1 do
      sign_in @user
      get root_path
    end

    session_record = @user.sessions.last
    assert_not_nil session_record
    assert_nil session_record.revoked_at
  end

  test "multiple requests do not create duplicate sessions" do
    sign_in @user
    get root_path

    assert_no_difference "Session.count" do
      get root_path
    end
  end

  test "sign-out soft-revokes the session (sets revoked_at, does NOT delete)" do
    sign_in @user
    get root_path
    session_record = @user.sessions.last

    assert_nil session_record.revoked_at

    delete destroy_user_session_path

    assert_not_nil session_record.reload.revoked_at
    # Record still exists (soft delete)
    assert_equal 1, Session.count
  end

  test "revoked session forces sign-out on next request" do
    sign_in @user
    get root_path

    # Simulate revoking from another device
    @user.sessions.last.revoke!

    # Next request detects revocation and force-signs-out
    get root_path

    # Subsequent request redirects to sign-in
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "touch_last_active! updates on fetch when stale" do
    sign_in @user
    get root_path

    session_record = @user.sessions.last
    session_record.update_column(:last_active_at, 10.minutes.ago)
    old_time = session_record.last_active_at

    get root_path

    assert session_record.reload.last_active_at > old_time
  end

  test "lazy-creates a Session when session_id exists but DB record is missing" do
    sign_in @user
    get root_path

    # Delete the record but keep the session_id in the cookie
    @user.sessions.delete_all

    assert_difference "Session.count", 1 do
      get root_path
    end
  end
end
```

## 9. Gotchas and decisions

### Why soft-delete instead of hard-delete?

Two reasons:
1. **Session history UI** — users can see past sessions even after sign-out.
2. **Revocation detection** — if a revoked cookie is still active in some browser, the `:fetch` hook needs the record to exist (with `revoked_at` set) to detect and force sign-out. If we hard-deleted, the hook would see "no record" and **lazy-create a new one**, re-authenticating the revoked session.

### Why `update_column` in `touch_last_active!`?

`update_column` skips validations and callbacks. For a simple timestamp update on every request, this avoids unnecessary overhead.

### Why `find_or_create_by!` instead of `create!` with `rescue RecordNotFound`?

`find_or_create_by!` handles the common case (record already exists) with a fast SELECT. The `RecordNotUnique` rescue only fires during the race condition window — not on every request.

### Why rescue `ActiveRecordError` in SessionManager?

Session tracking is a **non-critical feature**. If the database is temporarily unavailable or a constraint fails, the user should still be able to sign in and browse. The rescue prevents session tracking failures from breaking authentication. In production, you'd send these to your error tracker (Sentry, Honeybadger, etc.) instead of just logging.

### Why scope on `:user` in the hooks?

If your app uses multiple Devise scopes (e.g., `:user` and `:admin`), you must scope the hooks to the correct model. Replace `:user` with your scope. If you want session tracking for multiple scopes, duplicate the hooks for each.

### The `bypass_sign_in` edge case

Some apps sign in users programmatically with `bypass_sign_in` or `warden.set_user(user, run_callbacks: false)`. These skip Warden hooks entirely. If you have such a path, you must call `Session.track!` manually:

```ruby
def sign_in_programmatically(user)
  bypass_sign_in(user, scope: :user)
  warden.set_user(user, scope: :user, run_callbacks: false)

  # Hooks are skipped, so manually track the session:
  session_id = warden.session(:user)["session_id"] ||= SecureRandom.uuid
  Session.track!(user: user, session_id: session_id, request: request)
end
```

## Summary

The full implementation is 3 files of application code (model, manager, initializer) plus a migration. Warden's hook system makes this work transparently with every Devise sign-in strategy. The key design choices:

- **UUID per browser** stored in the encrypted session cookie
- **Soft-delete** via `revoked_at` for revocation detection
- **5-minute write throttle** on `last_active_at` to avoid DB write amplification
- **Race condition handling** via unique index + retry
- **Graceful degradation** for sessions that predate the feature
