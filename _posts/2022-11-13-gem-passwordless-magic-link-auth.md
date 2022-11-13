---
layout: post
title: "Passwordless: log in with magic link"
author: Yaroslav Shmarov
tags: passwordless authentication magic-link
thumbnail: /assets/thumbnails/lock.png
---

Passwordless authentication via magic link is an interesting alternative to email-password authentication solutions like Devise.

![passwordless-magic-link-form](/assets/images/passwordless-magic-link-form.png)

A passwordless authentication flow looks like this:
- Enter your email address
- Receive login link in an email
- Click link -> You are logged in

I've implemented passwordless authentication in [insta2blog.com](https://insta2blog.com), and for now I am super happy with the solution 🚀. Feel free to try it out!

[GIF]

In a way this is a more secure authenication strategy, because there is no compromised password point of failure. It is as secure as your email account. 

However to even start using this solution in production, you will need to set up [**sending emails in production**]({% post_url 2021-02-08-send-emails-in-production-amazon-ses %}).

It is not hard to create this kind of authentication solution on your own, however I prefer not to reinvent the wheel. [Gem `passwordless`](https://github.com/mikker/passwordless) neatly solves the problem.

Here's how the authentication (login) flow looks in my app:

![passwordless-magic-link-flow](/assets/images/passwordless-magic-link-flow.gif)

### 1. Install [gem passwordless](https://github.com/mikker/passwordless)

Apart of following the official installation guide, here are some of my improvements.

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
<% if current_user %>
  <%= current_user.email %>
  <%= button_to 'Sign out', auth.sign_out_path, method: :delete, form: { data: { turbo_confirm: 'Log out?' } } %>
<% else %>
  <%= link_to 'Sign in', auth.sign_in_path %>
<% end %>
```

### 2. Update email template

Preview magic link email with Rails ActionMailer previews:

```ruby
# test/mailers/previews/passwordless_mailer_preview.rb
class PasswordlessMailerPreview < ActionMailer::Preview
  # http://localhost:3000/rails/mailers/passwordless_mailer/magic_link
  def magic_link
    session = Passwordless::Session.first
    Passwordless::Mailer.magic_link(session).deliver_now
  end
end
```

Add better wording to the passwordless email:

```html
<!-- app/views/passwordless/mailer/magic_link.text.erb -->
Please confirm that you want to sign in to <%= Rails.application.class.module_parent.name %>.

<%= I18n.t('passwordless.mailer.magic_link', link: @magic_link) %>

The link will expire at <%= Passwordless.timeout_at.call %>

Confirming this request will securely log you in using <%= @session.authenticatable.email %>.

This login was requested using <%= @session.user_agent %>.

If you have any issues with your account, please don't hesitate to contact me by replying to this mail.

Thanks!

Yaro from <%= Rails.application.class.module_parent.name %>
```

![passwordless-mailer-preview](/assets/images/passwordless-mailer-preview.png)

### 3. Open emails in development

To automaticall open previews of sent emails (so that you can confirm a magic link), you will need the [**gem letter_opener**](https://github.com/ryanb/letter_opener) gem:

```
bundle add letter_opener
```

```ruby
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
```

![passwordless-letter-opener](/assets/images/passwordless-letter-opener.png)

### 4. Troubleshooting. Future development.

* Add `data: { turbo: 'false' }` for the redirect from the form to work.
* Add `required: true` for frontend validation of having an email present on submit.

```diff
-<%= form_for @session, url: send(Passwordless.mounted_as).sign_in_path do |f| %>
+<%= form_with model: @session, url: send(Passwordless.mounted_as).sign_in_path, data: { turbo: 'false' } do |f| %>
  <% email_field_name = :"passwordless[#{@email_field}]" %>
-  <%= text_field_tag email_field_name, params.fetch(email_field_name, nil) %>
+  <%= text_field_tag email_field_name, params.fetch(email_field_name, nil), required: true %>
  <%= f.submit I18n.t('passwordless.sessions.new.submit') %>
<% end %>
```

I've submitted these changes in [a PR to passwordless](https://github.com/mikker/passwordless/pull/128). Let's see if my changes come through.

That's it!
