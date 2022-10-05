---
layout: post
title: "Gem Kredis #3 - recently search results"
author: Yaroslav Shmarov
tags: ruby-on-rails redis kredis
thumbnail: /assets/thumbnails/redis.png
---

### Example 2: Latest search results

Add a form to search for a post by name:

```ruby
# app/views/posts/index.html.erb
<%= form_with url: posts_path, method: :get do |form| %>
  <%= form.search_field :query %>
<% end %>

<% current_user.recent_searches.elements.each do |query| %>
  <%= link_to query, root_path(query: query) %>
<% end %>

<%= params[:query] %>
```

Next, associate a Redis entity of `kredis_unique_list` with the `user.rb` model:

```ruby
# user.rb
  kredis_unique_list :recent_searches, limit: 5
```

When there is a search, save the search params to `current_user.recent_searches`. `prepend` will add it at the top of the list:

```ruby
# app/controllers/posts_controller.rb
def index
  @posts = if params[:query].present?
              Post.where(name: params[:query])
            else
              Post.all
            end
  current_user.recent_searches.prepend(params[:query]) if params[:query].present?
end
```

Recently visited pages

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
