---
layout: post
title: "#20 Turbo Streams: autocomplete search"
author: Yaroslav Shmarov
tags: ruby-on-rails-7 hotwire turbo autocomplete
thumbnail: /assets/thumbnails/turbo.png
---

It's very easy to add autocomplete search with turbo streams:
![turbo streams autocomplete search](assets/images/autocomplete-search.gif)

### 1. Initial setup

```ruby
# config/seeds.rb
100.times do
  Post.create(title: Faker::Movie.unique.title)
end
```

```ruby
# console
rails g scaffold post title
bundle add faker
rails db:migrate
rails db:seed
```

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true, uniqueness: true
end
```

### 2. Autocomplete search

* add a search route. It should be a `post` request, so that we can respond with turbo_stream

```ruby
# config/routes.rb
  resources :posts do
    collection do
      post :search
    end
  end
```

* now you can create a search form that leads to the above route;
* add `<div id="search_results"></div>` as a target where to render search results:

```ruby
# app/views/posts/_search_form.html.erb
<%= form_with url: search_posts_path, method: :post do |form| %>
  <%= form.search_field :title_search, value: params[:title_search], oninput: "this.form.requestSubmit()" %>
<% end %>

<div id="search_results"></div>
```

* add the `search` action in the controller;
* here we find the posts that contain our search query;
* we can render them with a turbo_stream in our search target

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def search
    @posts = Post.where('title ILIKE ?', "%#{params[:title_search]}%").order(created_at: :desc)
    respond_to do |format|
      format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("search_results",
            partial: "posts/search_results",
            locals: { posts: @posts })
          ]
      end
    end
  end
end
```

* add a partial with the search results;
* to make it sexy, highlight the matches:

```ruby
# app/views/posts/_search_results.html.erb
<%= posts.count %>
<% posts.each do |post| %>
  <br>
  <%= link_to post do %>
    <%= highlight(post.title, params.dig(:title_search)) %>
  <% end %>
<% end %>
```

That's it! Now you can render the search form anywhere:

```ruby
# app/views/posts/index.html.erb
<%= render "posts/search_form" %>
```
