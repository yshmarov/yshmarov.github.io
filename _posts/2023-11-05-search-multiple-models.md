---
layout: post
title: "Search multiple models"
author: Yaroslav Shmarov
tags: ruby-on-rails
thumbnail: /assets/thumbnails/search.png
---

On [superails.com](https://superails.com/) you can search for **Posts**, **Playlists** and **Tags** in one single search field:

![superails-search-multiple-models](/assets/images/sr-find-post-or-tags.gif)

[AVO](https://avohq.io/) offers a similar behaviour:

![avo-search-multiple-models](/assets/images/avo-search-multiple-models.gif)

Here's how You, dear `@Elgnonvis`, can add this kind of functionality to your app.

![youtube-Elgnonvis-requested](/assets/images/search-multiple-requested-by.png)

### Step 1. Display all `Posts`, `Tags`, `Users` on a page

```shell
rails g model Post title description
rails g model Tag name
rails g model User first_name last_name email
```

```ruby
# config/routes.rb
  get "dashboard", to: "pages#index"
```

```ruby
# app/controllers/dashboard_controller.rb
def index
  @posts = Post.all
  @users = User.all
  @tags = Tag.all
end
```

```ruby
# app/views/dashboard/index.html.erb
<div>
  Posts
  <% @posts.each do |post| %>
    <div>
      <%= highlight post.title, params[:query] %>
      <%= highlight post.description, params[:query] %>
    </div>
  <% end %>
</div>

<div>
  Users
  <% @users.each do |user| %>
    <div>
      <%= highlight user.first_name, params[:query] %>
      <%= highlight user.last_name, params[:query] %>
      <%= highlight user.email, params[:query] %>
    </div>
  <% end %>
</div>

<div>
  Tags
  <% @tags.each do |tag| %>
    <div>
      <%= highlight tag.name, params[:query] %>
    </div>
  <% end %>
</div>
```

### Step 2. Add a search form

```ruby
<%= link_to "Clear", dashboard_path if params[:query] %>

<%= form_with url: dashboard_path, method: :get do |form| %>
  <%= form.search_field :query, value: params[:query], placeholder: "Find anything", autofocus: true %>
  <%= form.submit %>
<% end %>
```

`ILIKE` is case-insensitive search anywhere in the text.

```ruby
# app/controllers/dashboard_controller.rb
def index
  if params[:query].present?
    @posts = Post.where("title ILIKE ? OR description ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
    @tags = Tag.where("name ILIKE ?", "%#{params[:query]}%")
    @users = User.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
  else
    @posts = []
    @tags = []
    @users = []
  end
end
```

In most cases, it is enough to stop on **"Step 2"**.

This is what I use at [superails.com](https://superails.com/)

No need to overcomplicate.

However sometimes you would want to automate the process of extending the list of `models` and `attributes` that can be searched.

### Step 3. Metaprogramming: dynamically set `models` and `attributes` that can be searched and displayed

```ruby
class DashboardController < ApplicationController
  SEARCHABLE_MODEL_ATTRIBUTES = {
    "Post" => ["title", "description"],
    "Tag" => ["name"],
    "User" => ["first_name", "last_name", "email"]
  }
  
  def index
    @search_results = {}

    if params[:query].present?
      SEARCHABLE_MODEL_ATTRIBUTES.each do |model_name, searchable_fields|
        model_results = model_name.constantize.
          where(searchable_fields.map { |field| "#{field} ILIKE :query" }.join(" OR "), query: "%#{params[:query]}%")
          .order(created_at: :desc)

        @search_results[model_name] = model_results
      end
    end
  end
end
```

Render a collection for each searchable model.

Render either a partial for each searchable model (`app/views/posts/_post.html.erb`, `users/_user.html.erb`, etc.), or the searchable fields.

```ruby
# app/views/dashboard/index.html.erb
<% if params[:query].present? %>
  <% DashboardController::SEARCHABLE_MODEL_ATTRIBUTES.each do |model_name, _searchable_fields| %>
    <% results = @search_results[model_name] %>
    <% next if results.empty? %>

    <h2>
      <%= model_name.pluralize %>
      <%= results.count %>
    </h2>
    <div>
      <% results.each do |result| %>
        <% searchable_fields.each do |searchable_field| %>
          <%= highlight result[searchable_field], params.dig(:query) %>
        <% end %>
        <%#= render "#{model_name.downcase.pluralize}/#{model_name.downcase}", model_name.downcase.to_sym => result %>
      <% end %>
    </div>
  <% end %>
<% end %>
```

Final result:

![search-multiple-models-final-result](/assets/images/multisearch-final-result.gif)

Now you can search any models and attributes by just updating `SEARCHABLE_MODEL_ATTRIBUTES`!

That's it! 🤠
