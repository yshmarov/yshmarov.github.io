---
layout: post
title: Rails 8 native rate limiting
author: Yaroslav Shmarov
tags: rack-attack rate-limiting
thumbnail: /assets/thumbnails/lock.png
---

Rate limiting sign up & sign in pages is important for securing your app from password-guessing attacks.

You can also add rate limitng to pages users are likely to abuse, like 

Previously I wrote about rate limiting with [Use Gem Rack-attack with Devise and Rails 7]({% post_url 2023-08-03-gem-rack-attack-devise-rails7 %}).

Recently rate limiting [was added](https://github.com/rails/rails/commit/179b979ddbb7bcc4d1a12d0d71779f47c1c9d9cd) to Rails by default.

You can see the latest docs [here](https://github.com/rails/rails/blob/main/actionpack/lib/action_controller/metal/rate_limiting.rb)

### Rate limiting devise registrations & signups

Add devise and import registrations & sessions controllers so that you can override them.

```bash
bundle add devise
rails g devise:install
rails g devise User
rails db:migrate
rails generate devise:controllers users -c=registrations sessions
```

```diff
# config/routes.rb
Rails.application.routes.draw do
-  devise_for :users
+  devise_for :users, controllers: { registrations: "users/registrations", sessions: "users/sessions" }
end
```

Add the `rate_limit` before_action. Rails suggests [this default rate_limit setting](https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/authentication/templates/controllers/sessions_controller.rb#L3).

```ruby
# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  # default
  # rate_limit to: 10, within: 3.minutes, by: -> { request.remote_ip }, with: -> { head :too_many_requests }
  # our approach
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_user_session_url, alert: "Try again later." }
  # test
  # rate_limit to: 2, within: 1.minute, only: :new
end
```

```ruby
# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_user_registration_url, alert: "Try again later." }
end
```

Now, when one user submits the sign_in or sign_up form >10 times within 3 minutes, he will get a blank page with a `429 Too Many Requests` error:

![rate-limit-many-requests](/assets/images/rate-limit-many-requests.png)

Or, as in this example, redirected with an alert:

![rate-limit-redirect](/assets/images/rate-limit-redirect.png) 

That's it! So simple.
