---
layout: post
title: "Recent search history with Kredis"
author: Yaroslav Shmarov
tags: ruby-on-rails redis kredis
thumbnail: /assets/thumbnails/redis.png
---

### Example 2: user preferences

```ruby
# app/models/user.rb
  kredis_hash :preferences
```

```diff
# app/views/posts/index.html.erb
-<% if params[:view] == "card" %>
-<% if @user_preferences[:view] == "card" %>
+<% if current_user.preferences[:view] == "card" %>
  <%= link_to "List view", players_path(view: "list") %>
  <%= render @players %>
<% else %>
  <%= link_to "Card view", players_path(view: "card") %>
  <%= render @players %>
<% end %>
```

```ruby
# app/controllers/posts_controller.rb
def index
  @players = Player.all
  # https://github.com/rails/kredis/blob/20aa4f272763151d462e9c9e125fcebf2eed4a5d/lib/kredis/types/hash.rb#L3
  # @user_preferences = Kredis.hash('preferences')
  # @user_preferences.update(view: params[:view]) if params[:view].present?
  current_user.preferences.update(view: params[:view]) if params[:view].present?
end
```
