Bearer Turbo Frame tabs

rails g scaffold client name
rails g scaffold task name client:references
rails g scaffold payment amount:integer client:references

```ruby
# app/views/..
<%= turbo_frame_tag :static_tabs, src: statics_comments_path, data: { turbo_frame: "_top", turbo_action: "advance" } %>
```

```ruby
class StaticsController < ApplicationController
  layout "tabs"
  def feed
  end

  def friends
  end

  def likes
  end

  def comments
  end
end
```

```ruby
# app/views/layouts/tabs.html.erb
<%= turbo_frame_tag :static_tabs do %>
  <%= render 'statics/navbar' %>
  <%= yield %>
<% end %>
```

```ruby
# app/views/static/navbar.html.erb
<header>
  <%= link_to_unless_current "comments", statics_comments_path %>
  <%= link_to_unless_current "feed", statics_feed_path %>
  <%= link_to_unless_current "friends", statics_friends_path %>
  <%= link_to_unless_current "likes", statics_likes_path %>
</header>
```

Negatives:
