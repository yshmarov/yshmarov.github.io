---
layout: post
title: "#14 Turbo + Devise"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails devise turbo hotwire
thumbnail: /assets/thumbnails/turbo.png
---

MISSION:
* fix `NoMethodError in Devise::RegistrationsController#create undefined method `user_url' for #<Devise::RegistrationsController:0x0000000000de58>`

* fix `No route matches [GET] "/users/sign_out"`

* fix `sign_in` - validation errors do not display

**TLDR: add `, data: { turbo: "false" }` / `"data-turbo" => "false"` to Devise `forms` and `buttons`**

****

I've been hearing that "devise & turbo don't play well yet" for many months, and I just waited...

Well, it's been 12 months since turbo was announced (Dec 20, 2020).

Now we have Turbo 7.0, Rails 7 alpha2, and [the Devise maintainer says that Devise is ready](https://twitter.com/heartcombo/status/1446256070306013186){:target="blank"}.

So, let's try to install devise on a Rails 7 alpha2 app (that uses Turbo by default).

### 0. Install `gem devise`

Gemfile - use main 
```diff
-- gem 'devise'
++ gem 'devise', github: 'heartcombo/devise', branch: 'main'
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

### 1. Add navigation links. Fix `log_out`

* Before, it was a simple `link_to`
* Now, it has to be a `button_to` with `data: { turbo: "false" }`

```diff
# app/views/layouts/application.html.erb
  <% if signed_in? %>
    <%= link_to current_user.email, edit_user_registration_path %>
--  <%#= link_to "Log out", destroy_user_session_path, method: :delete %>
--  <%#= button_to "Log out", destroy_user_session_path, method: :delete, form: { "data-turbo" => "false" } %>
++  <%= button_to "Log out", destroy_user_session_path, method: :delete, data: { turbo: "false" } %>
  <% else %>
    <%= link_to "Log in", new_user_session_path %>
    <%= link_to "Register", new_user_registration_path %>
  <% end %>
```

Alternatively, you can try a `link_to` with `data-turbo-method` `delete`:
```ruby
<%= link_to "Log Out", destroy_user_session_path, 'data-turbo-method': :delete %>
<%= link_to "Log out", destroy_user_session_path, data: { turbo_method: :delete" } %>
```

### 2. BUT ALL DEVISE FORMS DO NOT WORK!

We have to disable Turbo for devise (add `data: {turbo: false}` to all devise forms).

This is illustrated as a passable solution [in this discussion](https://github.com/heartcombo/devise/issues/5358#issuecomment-798796788){:target="blank"}.

```ruby
rails generate devise:views
# rails generate devise:views -v confirmations passwords registrations sessions
```

```diff
# app/views/devise/registrations/new.html.erb
-- <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
++ <%= form_for(resource, as: resource_name, url: registration_path(resource_name), html: { data: { turbo: false} } ) do |f| %>
```

```diff
# app/views/devise/sessions/new.html.erb
-- <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
++ <%= form_for(resource, as: resource_name, url: session_path(resource_name), html: { data: { turbo: false} } ) do |f| %>
```

That's it! Should work OK.

Yes, it is quite manual, but I do not see a better solution at the moment :(