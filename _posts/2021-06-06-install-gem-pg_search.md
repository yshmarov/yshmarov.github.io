---
layout: post
title: "Install and use gem pg_search"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails pg_search
thumbnail: /assets/thumbnails/postgresql.png
---

[pg_search](https://github.com/Casecommons/pg_search) builds ActiveRecord named scopes that take advantage of PostgreSQL’s full text search 

Gemfile
```ruby
gem 'pg_search'
```

app/controllers/posts_controller.rb
```ruby
def index
  if params[:query].present?
    @posts = Post.order(created_at: :desc).global_search(params[:query])
  else
    @posts = Post.order(created_at: :desc)
  end
end
```

app/models/post.rb - search by title
```ruby
include PgSearch::Model
# pg_search_scope :global_search, against: :title
```

OR app/models/post.rb - search by title AND content
```ruby
include PgSearch::Model
pg_search_scope :global_search, against: [:title, :content], using: { tsearch: { prefix: true } }
```

OR app/models/post.rb - search by title AND content AND associations
```ruby
include PgSearch::Model
pg_search_scope :global_search, associated_against: { tags: [:name, :category], user: :email, :title, :content }
```

app/views/posts/index.html.erb
```ruby
<%= form_with(url: posts_url, method: :get) do |f| %>
  <%= label_tag(:query, "Search for") %>
  <%= text_field_tag(:query) %>
  <%= submit_tag("Search", class: "btn btn-primary") %>
<% end %>
```
