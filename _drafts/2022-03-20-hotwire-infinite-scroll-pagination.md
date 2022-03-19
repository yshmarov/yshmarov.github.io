---
layout: post
title: "Hotwire: Infinite scroll pagination (Frames VS Streams)"
author: Phil Hayton, Yaroslav Shmarov
tags: rails hotwire
thumbnail: /assets/thumbnails/turbo.png
---

One of the reasons why I love RoR - you can have many great approaches to solve the same problem.

I've seen quite a lot of approaches to infinite scrolling, but didn't like them a lot.

Here's how I would do it with 2 different Hotwire approaches:
1. via Turbo Streams (autoload content)
2. via Turbo Frames (load more button)

Final Result:
![infinite-scroll-pagination.gif](/assets/images/infinite-scroll-pagination.gif)

![infinite-scroll-load-more-button.gif](/assets/images/infinite-scroll-load-more-button.gif)

### 1. Initial setup

scaffold posts, add some seeds

```ruby
# db/seeds.rb
100.times do
  Post.create(title: Faker::Music.band, image: Faker::Avatar.image)
  Comment.create(body: Faker::Quote.famous_last_words)
end
```

```sh
bundle add faker
bundle add pagy
rails g scaffold comment body:text --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
rails g scaffold post title image --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
rails db:migrate
rails db:seed
```

```ruby
# app/helpers/application_helper.rb
  include Pagy::Frontend
```

```ruby
# app/controllers/application_controller.rb
  include Pagy::Backend
```

### 2. Turbo Frames: Auto-loading Infinite scroll

```ruby
# app/controllers/posts_controller.rb
  def index
    @pagy, @posts = pagy(Post.order(created_at: :desc), items: 5)

    render "scrollable_list" if params[:page]
  end
```

```ruby
# app/views/posts/index.html.erb
<%= render partial: "post", collection: @posts %>
<%= render partial: "next_page" %>
```

```ruby
# app/views/posts/_next_page.html.erb
<%= turbo_frame_tag(
      "posts-page-#{@pagy.next}",
      # autoscroll: true,
      loading: :lazy,
      src: pagy_url_for(@pagy, @pagy.next),
      target: "_top"
    ) do %>
  Loading...
<% end %>
```

```ruby
# app/views/posts/scrollable_list.html.erb
<%= turbo_frame_tag "posts-page-#{@pagy.page}" do %>
  <%= render partial: "post", collection: @posts %>
  <%= render partial: "next_page" %>
<% end %>
```

helpers used:

```ruby
= @pagy.page # current page (1)
= @pagy.next # next page (2)
== pagy_next_link(@pagy, text: 'More...') # link to next page
= pagy_url_for(@pagy, @pagy.next) # url to next page (/posts&page=2)
```

```ruby
# config/initializers/pagy.rb
# https://ddnexus.github.io/pagy/extras/support.html#gsc.tab=0
# require 'pagy/extras/support'
```

### 2. Turbo Streams: Click to load more

* add a link to next page

```ruby
# app/views/comments/index.html.erb
  <div id="comments">
    <%= render @comments %>
  </div>

  <div id="next_link">
    <%= button_to "next", pagy_url_for(@pagy, @pagy.next) %>
  </div>
```

* add pagination to the controller
* allow to respond to `POST` requests for `turbo_streams`

```ruby
# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  def index
    @pagy, @comments = pagy(Comment.order(created_at: :desc), items: 5)

    respond_to do |format|
      format.html # GET
      format.turbo_stream # POST
    end
  end
end
```

* allow index_path to respond to `POST`, not only `GET`

```ruby
# config/routes.rb
  resources :comments do
    collection do
      post :index
    end
  end
```

* add new comments on the bottom of the list
* re-render the `next` button with a new URL

```ruby
# app/views/comments/index.turbo_stream.erb
<%= turbo_stream.append "comments" do %>
  <%= render partial: "comment", collection: @comments %>
<% end %>

<%= turbo_stream.update "next_link" do %>
  <% if @pagy.next.present? %>
    <%= button_to "next", pagy_url_for(@pagy, @pagy.next) %>
  <% end %>
  <%#== pagy_next_link(@pagy, text: 'More...') %>
  <%#= pagy_url_for(@pagy, @pagy.next) %>
<% end %>
```

### 3. Without a pagination gem

Here's how a friend of mine, [Phil @gotbadger](twitter.com/gotbadger){:target="blank"}, accomplished this.
100% credit this goes to Phil 💪 !

The approach:
❌ No JS
❌ No Turbo Streams
✅ Some backend RoR
✅ Turbo Frames


By default, a turbo_frame only loads when it becomes **visible** in the DOM, as I've [shown in another example]({% post_url 2021-11-01-turbo-lazy-loading-dropdown %}){:target="blank"}. 

Knowing this, we can create a recursion.

turbo_frame_tag has ScrollIntoView

```ruby
# app/controllers/posts_controller.rb
  POSTS_PER_PAGE = 5

  def index
    @cursor = (params[:cursor] || "0").to_i
    @posts = Post.all.where("id > ?", @cursor).order(:id).take(POSTS_PER_PAGE)
    @next_cursor = @posts.last&.id
    @more_pages = @next_cursor.present? && @posts.count == POSTS_PER_PAGE

    render "scrollable_list" if params[:cursor]
  end
```

Initially the localhost:3000/posts returns `index.html.erb`.

When the page scrolls down to the `turbo_frame` in `next_page` partial, it goes pack to `posts#index` in the controller with a `params[:cursor]` and renders `scrollable_list.html.erb` instead of `index.html.erb`.

```ruby
# app/views/posts/index.html.erb
<%= render partial: "post", collection: @posts %>
<%= render partial: "next_page" %>
```

`@cursor` - 
`@more_pages` - 
`@next_cursor` - 

```ruby
# app/views/posts/_next_page.html.erb
<% if @more_pages %>
  <%= turbo_frame_tag(
        "posts-page-#{@next_cursor}",
        autoscroll: true,
        loading: :lazy,
        src: posts_path(cursor: @next_cursor),
        target: "_top"
      ) do %>
    Loading...
  <% end %>
<% end %>
```

```ruby
# app/views/posts/scrollable_list.html.erb
<%= turbo_frame_tag "posts-page-#{@cursor}" do %>
  <%= render partial: "post", collection: @posts %>
  <%= render partial: "next_page" %>
<% end %>
```
