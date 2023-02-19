---
layout: post
title: "Recent search history with Kredis"
author: Yaroslav Shmarov
tags: ruby-on-rails redis kredis
thumbnail: /assets/thumbnails/redis.png
---

**Why use Redis?** Hitting kredis is much cheaper than hitting a relational database. By storing high-frequency data on Redis we save resources.

**Wtf Kredis?** Kredis makes using Redis easier in Rails, and most importantly helps to associate Redis object with Rails Models.

Previously I wrote about ["Recently visited pages with Kredis"]({% post_url 2022-06-21-kredis-recently-visited-pages %}){:target="blank"}

"**Recent search history**" is a very similar feature in terms of implementation.

Feature description:
- whenever a user submits a search form, the search query is saved in redis
- display the users last 5 search queries

**Prerequisites**:
- scaffold `Posts title:string`
- Authentication, `current_user`

**Implementation**:

First, add `recent_searches` kredis attribute to User model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  kredis_unique_list :recent_searches, limit: 5
end
```

Add a search form:

```ruby
# app/views/posts/index.html.erb
<%= form_with url: posts_path do |form| %>
  <%= form.text_field :query %>
  <%= form.submit %>
<% end %>
```

If the form was submitted, add the latest search result to the list:

```ruby
# app/controllers/posts_controller.rb
def index
  if params[:query]
    @posts = Post.where('title ILIKE ?', "%#{params[:query]}%").order(created_at: :desc)
    current_user.recent_searches.prepend(params[:query]) # THIS
  else
    @posts = Post.all.order(created_at: :desc)
  end
end
```

Display a list of clickable recent searches:

```ruby
# app/views/users/_recently_searches.html.erb
<% current_user.recent_searches.elements.each do |query| %>
  <%= link_to query, posts_path(query:) %>
<% end %>
```

That's it!
