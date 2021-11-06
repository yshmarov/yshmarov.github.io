---
layout: post
title: "#14 Turbo + Devise"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails devise turbo hotwire
thumbnail: /assets/thumbnails/turbo.png
---

MISSION:
* fix `registration`:
```ruby
NoMethodError in Devise::RegistrationsController#create
undefined method `user_url' for #<Devise::RegistrationsController:0x0000000000de58>
```
* fix `log_out`:
```ruby
No route matches [GET] "/users/sign_out"
```
* `sign_in` - validation errors do not display

**TLDR: add `, data: { turbo: "false" }` / `"data-turbo" => "false"` to Devise `forms` and `buttons`**

****

I've been hearing that "devise & turbo don't play well yet" for many months, and I just waited...

Well, it's been 10 months since turbo was announced (Dec 20, 2020).

Now we have Turbo 7.0, Rails 7 alpha2, and [the Devise maintainer says that Devise is ready](https://twitter.com/heartcombo/status/1446256070306013186){:target="blank"}.

So, let's try to install devise on a Rails 7 alpha2 app (that uses Turbo by default)

### 0. Install `devise`

Gemfile - use main 
```diff
-- gem "devise" # use last release
-- gem "devise", github: "heartcombo/devise" # use git source
++ gem 'devise', github: 'heartcombo/devise', branch: 'main' # use main. it's stable.
```

```sh
rails generate devise:install
rails generate devise User
rails db:migrate
```

```ruby
# app/controllers/application_controller.rb
  before_action :authenticate_user!
```

### 1. Fix `log_out`

```diff
# app/views/layouts/application.html.erb
  <% if signed_in? %>
    <%= link_to current_user.email, edit_user_registration_path %>
--    <%#= link_to "Log out", destroy_user_session_path, method: :delete %>
--    <%#= button_to "Log out", destroy_user_session_path, method: :delete, form: { "data-turbo" => "false" } %>
++    <%= button_to "Log out", destroy_user_session_path, method: :delete, data: { turbo: "false" } %>
  <% else %>
    <%= link_to "Log in", new_user_session_path %>
    <%= link_to "Register", new_user_registration_path %>
  <% end %>
```

### 2. Fix `registration`

```diff
-- rails generate devise:views
++ rails generate devise:views -v registrations
```

```diff
# app/views/devise/registrations/new.html.erb
-- <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
++ <%= form_for(resource, as: resource_name, url: registration_path(resource_name), html: { data: { turbo: false} } ) do |f| %>
```

### 3. Fix `sign_in`

Validation errors do not display. This has to be fixed.

```diff
-- rails generate devise:views
++ rails generate devise:views -v sessions
```

```diff
# app/views/devise/sessions/new.html.erb
-- <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
++ <%= form_for(resource, as: resource_name, url: session_path(resource_name), html: { data: { turbo: false} } ) do |f| %>
```

That's it! Should work perfectly.

[More details about THIS solution](https://github.com/heartcombo/devise/issues/5358#issuecomment-798796788){:target="blank"}
