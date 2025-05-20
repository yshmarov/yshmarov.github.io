---
layout: post
title: "Install and use gem pg_search"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails pg_search
thumbnail: /assets/thumbnails/postgresql.png
---

[pg_search](https://github.com/Casecommons/pg_search) builds ActiveRecord named scopes that take advantage of PostgreSQL’s full text search

```ruby
# Gemfile
gem 'pg_search'
```

```ruby
# app/controllers/posts_controller.rb
def index
  if params[:query].present?
    @posts = Post.order(created_at: :desc).global_search(params[:query])
  else
    @posts = Post.order(created_at: :desc)
  end
end
```

search by title

```ruby
# app/models/post.rb
include PgSearch::Model
# pg_search_scope :global_search, against: :title
```

OR search by title AND content

```ruby
# app/models/post.rb
include PgSearch::Model
pg_search_scope :global_search, against: [:title, :content], using: { tsearch: { prefix: true } }
```

OR search by title AND content AND associations

```ruby
# app/models/post.rb
include PgSearch::Model
pg_search_scope :global_search, associated_against: { tags: [:name, :category], user: :email, :title, :content }
```

```ruby
# app/views/posts/index.html.erb
<%= form_with(url: posts_url, method: :get) do |f| %>
  <%= label_tag(:query, "Search for") %>
  <%= text_field_tag(:query) %>
  <%= submit_tag("Search", class: "btn btn-primary") %>
<% end %>
```

Advanced setup:

```ruby
# app/models/post.rb
  pg_search_scope :global_search,
    against: {
      title: "A",
      content: "C"
    },
    associated_against: {
      user: {email: "C"},
      tags: [:name, :category],
    },
    using: {
      tsearch: {
        dictionary: "english",
        prefix: true,
        any_word: true
      },
      trigram: {threshold: 0.3}
    },
    ranked_by: ":tsearch + (0.5 * :trigram)",
    ignoring: :accents
```

That's it!
