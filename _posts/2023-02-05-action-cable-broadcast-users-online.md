---
layout: post
title: "Realtime Online User Tracking with Actioncable and Rails"
author: Yaroslav Shmarov
tags: ruby rails kredis action-cable hotwire turbo broadcasts
thumbnail: /assets/thumbnails/users-online-symbol.png
---

Some time ago I wrote about [**Tracking Online Users using Timestamps**]({% post_url 2020-08-16-set-user-status-online %}){:target="blank"}. However these "timestamps" would require constantly hitting the relational database whenever a user does an action. This could cause performance issues.

Instead, you could use **Redis** to store this *temporary* data. After all, isn't that what Redis exists for?!

Also, a more accurate way to track whether someone is **actually online** is to check if he has an active Websockets connection with your app.

In the previous post I wrote about tracking [**live visitor count**]({% post_url 2023-02-02-action-cable-broadcast-visitors-online %}){:target="blank"}. We identified a vistor by a `session_id` without authentication.

The only difference here is that we identify an authenticated `current_user` if there is one.

Prerequisites:
- Have authentication installed (Devise or anything else).
- Install [gem Kredis](https://github.com/rails/kredis#installation){:target="blank"}

Result - you can have a "live list of online users":

![dashboard-with-all-online-users.gif](/assets/images/dashboard-with-all-online-users.gif)

### Step 1: Create live list of online users

First, pass the `current_user.id` to the [ActionCable Connection](https://guides.rubyonrails.org/action_cable_overview.html#connection-setup){:target="blank"}.

This can vary on the authentication solution that you are using.

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # if current_user = User.find_by(id: cookies.encrypted[:user_id])
      if current_user = env['warden'].user # For Devise. Credit: @secretpray
        current_user
      else
        # reject_unauthorized_connection
        nil # Allow not logged in users to access the connection
      end
    end
  end
 end
```

Now you can access `current_user` in a **Channel**.

Create a turbo stream that would target an ActionCable Channel.

```ruby
# app/views/layouts/application.html.erb
<%= turbo_stream_from "online_users", channel: OnlineChannel %>
```

Next, create
- `< Turbo::StreamsChannel` & `super` to make `turbo_stream_from` correctly connect to ActionCable
- create a `Kredis.unique_list` where you will store ids of all users online
- broadcast current_user to the list of users online (server-side render the HTML)
- if the user logs out or closes all his browser sessions, he will be removed from the list of online users

```ruby
# app/channels/online_channel.rb
class OnlineChannel < Turbo::StreamsChannel
  def subscribed
    super
    return unless current_user
    users_online = Kredis.unique_list "users_online", expires_in: 5.seconds
    users_online << current_user.id
    # users_online.elements
    # users_online.elements.count
    Turbo::StreamsChannel.broadcast_prepend_to(
      verified_stream_name_from_params,
      target: 'users-list',
      partial: 'users/user',
      locals: { user: current_user }
    )
  end

  def unsubscribed
    return unless current_user
    users_online = Kredis.unique_list "users_online"
    users_online.remove current_user.id
    Turbo::StreamsChannel.broadcast_remove_to(
      verified_stream_name_from_params,
      target: "user_#{current_user.id}",
    )
  end
end
```

### Step 2: Display all users that are online.

In the controller, find all users that are online from the Kredis list:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  # skip_before_action :authenticate_user!, only: %i[ index ]

  def index
    users_online = Kredis.unique_list "users_online"
    @users = User.find(users_online.elements)
  end
end
```

Display the users in the view:

```ruby
# app/views/users/index.html.erb
<div id="users-list">
  <% @users.each do |user| %>
    <%= render partial: 'users/user', locals: { user: } %>
  <% end %>
<div>
```

```ruby
# app/views/users/_user.html.erb
<div id="<%= dom_id(user) %>">
  <%= user.email %>
</div>
```

Turbo broadcasts that we have added in `app/channels/online_channel.rb` will add/remove users from the list!

Important notice: when a user logs out, he will still be online until he refreshes the pages, closes the tab, or redirects to another website. This is because the ActionCable connection needs to be reset.

That's it. Now you can track all **visitors** on the website, track visitors in a room, track all online users. Thanks to ActionCable (Websockets), Kredis and Turbo Broadcasts!
