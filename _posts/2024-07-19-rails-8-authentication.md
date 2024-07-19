---
layout: post
title: "Rails 8 Authentication generator"
author: Yaroslav Shmarov
tags: rails devise authentication
thumbnail: /assets/thumbnails/lock.png
---

Recently DHH [merged a PR](https://github.com/rails/rails/pull/52328) that adds an authentication generator to Rails.

Currently the generator allows email-password log in for existing users. It does not tackle registrations.

Let's try it out!

Create a new app using Rails `main` branch:

```shell
rails new authy -c=tailwind --main
```

Run the generator & create a user

```shell
bin/rails generate sessions
rails db:create db:migrate
rails c
User.create(email_address: "foo@bar", password: "foo@bar")
```

Create pages that should be accessible with & without authentication:

```shell
rails g controller home index dashboard
```

Now your routes should look like this:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get "dashboard", to: "home#dashboard"
  resource :session, only: %i[new create destroy]
  root "home#index"
end
```

Only authenticated users can visit dashboard:

```diff
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  # allow users that are not logged in to see #index
+  allow_unauthenticated_access(only: :index)
  # make Current.user available on unauthenticated pages
+  before_action :resume_session, only: [:index]

  def index
  end

  def dashboard
  end
end
```

Display sign in/out links:

```diff
# app/views/layouts/application.html.erb
<body>
+  <%= link_to 'Home', root_path %>
+  <%= link_to 'Dashboard', dashboard_path %>
+  <% if authenticated? %>
+    <%= Current.user.email_address %>
+    <%= button_to 'Sign out', session_path, method: :delete %>
+  <% else %>
+    <%= link_to 'Sign in', new_session_path %>
+  <% end %>
+  <hr>
  <main class="container mx-auto mt-28 px-5 flex flex-col">
    <%= yield %>
  </main>
</body>
```

Test the new controller.

For some reason, Current attributes are not available for me in the controller test.

```ruby
# test/controllers/home_controller_test.rb
require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should get dashboard" do
    get dashboard_url
    assert_redirected_to new_session_url

    user = User.create!(email_address: "yaro@example.com", password: "123abc")
    post session_url, params: { email_address: 'yaro@example.com', password: '123abc' }

    get dashboard_url
    assert_response :success
    assert_match user.email_address, response.body
    # assert_equal user.email_address, Current.user.email_address

    delete session_url
    assert_redirected_to new_session_url
    get dashboard_url
    assert_redirected_to new_session_url

    # assert_nil Current.session
    # assert_nil Current.user
  end
end
```

Fix `undefined method 'destroy' for nil:NilClass` when trying to log out:

```diff
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
-  allow_unauthenticated_access
+  allow_unauthenticated_access(only: %i[new create])
```

Display error message when unauthenticated user requests a page that requires authentication:

```diff
# app/controllers/concerns/authentication.rb
    def request_authentication
      session[:return_to_after_authenticating] = request.url
-      redirect_to new_session_url
+      redirect_to new_session_url, alert: "Authenticate to access this page."
    end
```

I think this errors will be fixed soon. It could be a good first PR into rails/rails!
