---
layout: post
title: "#22 Hotwire Turbo: Broadcast Live Notifications"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo broadcasts
thumbnail: /assets/thumbnails/turbo.png
---

Previously we have:
* added [Turbo Streams Flash Messages]({% post_url 2021-10-29-turbo-hotwire-flash-messages %}){:target="blank"}
* added [Turbo Broadcasts]({% post_url 2021-12-09-turbo-hotwire-broadcasts %}){:target="blank"}

Now we will combine the two, and go deeper into Broadcasting.

****

However, when using turbo streams,

To render messages .... **Turbo Stream Broadcasts**.

* Flash - stateless - not
* Notifications in DB - can be marked as read
* Email/Third party

### Streams vs Broadcasts

* **Turbo Streams** - when you as a user do something, you see changes. to current_user
  Example:
    - you like a message - like counter increases
* **Turbo Broadcasts** - changes that are sent to you independent of your action.
  Examples:
    - someone sends you a message - you see +1 in your inbox
    - someone goes online/offline
    - a process has been completed

### Broadcasting basics

- trigger model callback
- trigger model action from controller
- trigger from controller

Unlike regular Streams, Broadcasts require an additional `channel` parameter.

A user can be subscribed to Multiple channles.

Common channel examples:
- `global_notifications` - to all users
- `current_user` - 
- `chat` - people who have a chat.id open

### Broadcast to everybody when a user goes online

`after_database_authentication`

https://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html

[Devise::Models::DatabaseAuthenticatable#after_database_authentication](https://www.rubydoc.info/github/plataformatec/devise/Devise%2FModels%2FDatabaseAuthenticatable:after_database_authentication)

https://github.com/heartcombo/devise/blob/main/lib/devise/models/database_authenticatable.rb#L168

### 1. Broadcast flash from any controller

```ruby
# app/views/layouts/application.html.erb
  <%= turbo_stream_from :global_notifications %>
  <%= render 'shared/flash' %>

<%= turbo_stream_from(current_user) if user_signed_in? %>
```

```ruby
# app/views/shared/flash.html.erb
<div id="flash">
  <div data-controller="autohide">
    <%= Time.zone.now %>
    <% flash.each do |key, value| %>
      <%= content_tag :div, value, id: key %>
    <% end %>
  </div>
</div>
```

```ruby
# any controller
flash.now[:notice] = "yaroro #{Time.zone.now}"
Turbo::StreamsChannel.broadcast_update_to('global_notifications',
                                          target: 'flash',
                                          partial: "shared/flash",
                                          locals: { flash: flash })
```

****

### 2. Broadcast global notification when a user signes in

#### 2.2. via `after_sign_in_path_for`

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource)
    flash.now[:notice] = "#{resource.email} yaroro #{Time.zone.now}"
    Turbo::StreamsChannel.broadcast_append_to('global_notifications', target: 'flash', partial: "shared/flash", locals: {flash: flash})
    return inboxes_path
  end
  end
```

#### 2.2. via `devise controllers`

```ruby
rails generate devise:controllers users -c sessions omniauth_callbacks
```

```ruby
# routes.rb
  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks",
                            sessions: 'users/sessions' }
```

```ruby
# app/controllers/users/sessions_controller.rb
  def create
    current_user.send_online_notification
    super
  end
```

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
  ...
  if @user.persisted?
    @user.send_online_notification
  ...
```

```ruby
# app/models/user.rb
  def send_online_notification
    broadcast_update_to('global_notifications',
                        target: 'yaro',
                        html: "#{self.email} has logged in at #{Time.zone.now}")
  end
```

****
binding.break
logger.debug "dfv"


****

    broadcast_update_to([user, :comments], target: "#{dom_id(comment)}_#{choice}_title", html: new_title)
