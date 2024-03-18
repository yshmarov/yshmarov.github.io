---
layout: post
title: "Passwordless: log in with magic link"
author: Yaroslav Shmarov
tags: passwordless authentication magic-link
thumbnail: /assets/thumbnails/lock.png
youtube_id: 00xl7yP7Yvs
---

Passwordless authentication via magic link is an interesting alternative to email-password authentication solutions like Devise.

For the first ever time I saw passwordless login in Slack:

![passwordless-slack-example](/assets/images/passwordless-slack-example.png)

A passwordless authentication flow looks like this:
1. Enter your email address
2. Receive **login link** or/and **token** in an email
3. Click link/Input token -> You are logged in

I've implemented passwordless authentication in [insta2blog.com](https://insta2blog.com), and for now I am super happy with the solution 🚀. Feel free to try it out!

![passwordless-magic-link-form](/assets/images/passwordless-magic-link-form.png)

In a way this is a more secure authenication strategy, because there is no compromised password point of failure. It is as secure as your email account. 

However to even start using this solution in production, you will need to set up [**sending emails in production**]({% post_url 2021-02-08-send-emails-in-production-amazon-ses %}).

It is not hard to create this kind of authentication solution on your own, however I prefer not to reinvent the wheel. [Gem `passwordless`](https://github.com/mikker/passwordless) neatly solves the problem.

Here's how the authentication (login) flow looks in my app:

![passwordless-magic-link-flow](/assets/images/passwordless-magic-link-flow.gif)

### 1. Install [gem passwordless](https://github.com/mikker/passwordless)

Apart of following the official installation guide, here are some of my improvements:

The routes helper

```ruby
# config/routes.rb
  passwordless_for :users
```

will generate
```ruby
Prefix Verb                 URI Pattern                         Controller#Action
users_sign_in GET           /users/sign_in(.:format)            passwordless/sessions#new {:authenticatable=>:user, :resource=>:users}
POST                        /users/sign_in(.:format)            passwordless/sessions#create {:authenticatable=>:user, :resource=>:users}
verify_users_sign_in GET    /users/sign_in/:id(.:format)        passwordless/sessions#show {:authenticatable=>:user, :resource=>:users}
confirm_users_sign_in GET   /users/sign_in/:id/:token(.:format) passwordless/sessions#confirm {:authenticatable=>:user, :resource=>:users}
PATCH                       /users/sign_in/:id(.:format)        passwordless/sessions#update {:authenticatable=>:user, :resource=>:users}
users_sign_out GET|DELETE   /users/sign_out(.:format)           passwordless/sessions#destroy {:authenticatable=>:user, :resource=>:users}
```

Update user model, enable user creation:

```ruby
# app/models/user.rb
  # add email regex validation
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  passwordless_with :email

  # add this so that users can be created!
  # don't add this if you want your app to be invite-only
  def self.fetch_resource_for_passwordless(email)
    find_or_create_by(email:)
  end
```

Requiring user only for specific actions in a controller:

```ruby
# app/controllers/posts_controller.rb
  before_action :require_user!, only: %i[new create edit update destroy]
```

Skip user requirement for specific actions:

```ruby
# app/controllers/posts_controller.rb
  skip_before_action :require_user!, only: %i[index show]
```

Login/Logout links:

```ruby
# app/views/layouts/application.html.erb
<%= notice %>
<%= alert %>
<% if current_user %>
  <%= current_user.email %>
  <%= button_to 'Sign out', users_sign_out_path, method: :delete, form: { data: { turbo_confirm: 'Log out?' } } %>
<% else %>
  <%= link_to 'Sign in', users_sign_in_path %>
<% end %>
```

### 2. Email template preview

Preview magic link email with Rails ActionMailer previews:

```ruby
# test/mailers/previews/passwordless_mailer_preview.rb
class PasswordlessMailerPreview < ActionMailer::Preview
  # http://localhost:3000/rails/mailers/passwordless_mailer/sign_in
  def sign_in
    user = User.build(email: 'foo@bar.com')
    session = Passwordless::Session.create!(authenticatable: user)
    Passwordless::Mailer.sign_in(session)
  end
end
```

![passwordless-mailer-preview](/assets/images/passwordless-mailer-preview.png)

### 3. Open emails in development

To automaticall open previews of sent emails (so that you can confirm a magic link), you will need the [**gem letter_opener**](https://github.com/ryanb/letter_opener) gem:

```shell
$ bundle add letter_opener
```

```diff
# /config/environments/development.rb
+ Rails.application.routes.default_url_options[:host] = 'localhost:3000'
Rails.application.configure do
+  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
+  config.action_mailer.delivery_method = :letter_opener
+  config.action_mailer.perform_deliveries = true
+  config.action_mailer.raise_delivery_errors = true
```

![passwordless-letter-opener](/assets/images/passwordless-letter-opener.png)

### 4. Custom config

```ruby
# config/initializers/passwordless.rb
Passwordless.configure do |config|
  config.default_from_address = "login@insta2blog.com"
  config.success_redirect_path = '/dashboard'
end
```

### 5. [Sign in via QR](https://github.com/mikker/passwordless/wiki/sign-in-via-QR-code-%F0%9F%93%B8)

That's it!
