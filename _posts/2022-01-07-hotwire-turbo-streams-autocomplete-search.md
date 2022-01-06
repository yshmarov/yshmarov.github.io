---
layout: post
title: "#20 Turbo Streams: autocomplete search"
author: Yaroslav Shmarov
tags: ruby-on-rails-7 hotwire turbo autocomplete
thumbnail: /assets/thumbnails/turbo.png
---

It's very easy to add autocomplete search with turbo streams:

![turbo streams autocomplete search nice UI](assets/images/sexier-autocomplete-search.gif)

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

Now you can render the search form anywhere:

```ruby
# app/views/posts/index.html.erb
<%= render "posts/search_form" %>
```

That's it!

... or do you still want to go further?

### 3. Don't make requests on empty input

As [@gvpmahesh suggested](https://twitter.com/gvpmahesh/status/1478920884941295617){:target="blank"},
In the above approach, if you clear your search input, you still query the database to return 0 results. Makes no sence!

* if search query is empty - render empty array of posts:

```ruby
# app/controllers/posts_controller.rb
  def search
    if params.dig(:title_search).present?
      @posts = Post.where('title ILIKE ?', "%#{params[:title_search]}%").order(created_at: :desc)
    else
      @posts = []
    end
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
```

### 4. Move query to model

Let's improve even more!

* add a scope to the model:

```ruby
# app/models/post.rb
  scope :filter_by_title, -> (title) { where('title ILIKE ?', "%#{title}%") }
```

* add the scope to the controller:

```ruby
# app/controllers/posts_controller.rb
  @posts = Post.filter_by_title(params[:title_search]).order(created_at: :desc)
  # @posts = Post.where('title ILIKE ?', "%#{params[:title_search]}%").order(created_at: :desc)
```

This approach is much more mature!

### 5. Debounce to limit number of queries

To send fewer requests to the databse, you can add a stimulus controller to submit form with a 500ms delay.

* add a stimulus controller that will submit the form with a delay:

```js
// app/javascript/controllers/debounce_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form" ]

  connect() { console.log("debounce controller connected") }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
        this.formTarget.requestSubmit()
      }, 500)
  }
}
```

* add the stimulus controller to the form `data: { controller: 'debounce' }`
* add the submit target to the form `data: { debounce_target: 'form' }`
* trigger the debounce#search on the input field `data: { action: "input->debounce#search" }`

```ruby
# app/views/posts/_search_form.html.erb
<%= form_with url: search_posts_path, method: :post, data: { controller: 'debounce', debounce_target: 'form' } do |form| %>
  <%= form.search_field :title_search, value: params[:title_search], data: { action: "input->debounce#search" } %>
<% end %>
```

### Final result:

![turbo streams autocomplete search basic](assets/images/autocomplete-search.gif)

### Final thoughts: Postgresql optimisation?

Do we expect the posts table to get quite big?

I think that even if this table is small now, we may need to create two indexes for the title column.

One of type BTREE (for equality comparisons) and one of type GIN (for pattern matching).

For the latter, we will also need to add the pg_trgm extension first in a separate migration.
