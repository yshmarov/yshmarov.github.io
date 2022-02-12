---
layout: post
title: "#22 Hotwire Turbo: Tips & Tricks"
author: Yaroslav Shmarov
tags: ruby-on-rails-7 hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

### 1. Turbo Streams: Stream from a controller

You can render one or multiple streams from a controller.

* single stream:

```ruby
# app/controllers/posts_controller.rb
def create
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.update("posts_count", Post.count)
    end
  end
end
```

* multiple streams:

```ruby
# app/controllers/posts_controller.rb
def create
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.update("posts_count", Post.count),
        turbo_stream.append("posts", partial: "posts/post", locals: {post: @post})
      ]
    end
  end
end
```

However DHH recommends to stream multiple streams by using a *.turbo_stream.erb template 👇

### 2. Turbo Streams: Stream from a template

* respond with a template:

```ruby
# app/controllers/posts_controller.rb
def create
  respond_to do |format|
    format.turbo_stream
  end
end
```

This allows you to comfortably respond with blocks of HTML:

```ruby
# app/views/posts/create.turbo_stream.erb

# stream html:
<%= turbo_stream.update "posts_count", Post.count %>

# stream a partial:
<%= turbo_stream.append("posts", partial: "posts/post", locals: {post: @post}) %>

# stream a template:
<%= turbo_stream.append("posts", partial: "posts/post", locals: {post: @post}) %>

# remove content from a DOM:
<%= turbo_stream.update "modal", nil %>

# stream a block:
<%= turbo_stream.replace "flash" do %>
  <div class="flash">
    A post has been created
  </div>
<% end %>

# stream a block. perfect example - a field:
<% if @post.user.present? %>
  <%= turbo_stream.update "user_id" do %>
    <input value="<%= @user.id %>"
          type="text"
          name="inventory_component[user_id]"
          id="post_user_id"
          >
  <% end %>
<% end %>
```

Don't forget that you can specify a template to respond with:

```ruby
format.turbo_stream { render template: "posts/another_template" }
```

My rule of thumb: 
* To stream a block of html or have some conditionals -> use a turbo_stream.erb template.
* To stream a value, text, partial or template -> stream from controller.

### ??? explicitly state template name. say which template to respond with

Next step - you can also respond with different turbo templates based on url params

```ruby
<%= button_to "1", posts_path(option_one: true), method: :post %>
<%= button_to "2" posts_path(option_two: true), method: :post %>
```

```ruby
  def select
    if params[:option_one].present?
      respond_to do |format|
        format.turbo_stream { render template: "big_bear_apis/first_template" }
      end
    elsif params[:option_two].present?
      respond_to do |format|
        format.turbo_stream { render template: "big_bear_apis/second_template" }
      end
    end
  end
```

### 4. Turbo Drive: `link_to` non-get request

* Before, using `rails-ujs`:

```ruby
link_to "Upvote", [:upvote, post], method: :post
link_to "Delete", post, method: :delete
```

* After, using turbo `'data-turbo-method'`:

```ruby
link_to "Upvote", [:upvote, post], 'data-turbo-method': :patch
link_to "Delete", post, data: { turbo_method: :delete }
```

* Anyway, it is always a better approach to use `link_to` for `GET` requests, and `button_to` `POST` `PUT` `PATCH` `DELETE`:

```ruby
button_to "Upvote", [:upvote, post], method: :patch
button_to "Delete", post, method: :delete
```

### 5. Turbo Drive: `Window.confirm()`

[Window.confirm()](https://developer.mozilla.org/en-US/docs/Web/API/Window/confirm) is a browser behavior that can be triggered with javascript to enforce the user to confirm an action.

* Before, using `rails-ujs`:

```ruby
link_to "Delete", post, method: :delete, data: { confirm: "Are you sure?" }
```

* After, using turbo `'data-turbo-confirm'`:

```ruby
link_to "Delete", post, data: { turbo_method: :delete, turbo_confirm: "Are you sure?" }
```

### 5. Turbo Frames: Autoscroll

`autoscroll: true`

```ruby
<%= link_to "X", new_post_path, data: {turbo_frame: "modal"} %>
```

```ruby
<%= turbo_frame_tag "modal", src: new_post_path, autoscroll: true, data: {turbo_action: "advance"} do %>
  Loading...
<% end %>
```

### 6. Turbo Frames: Update browser URL while navigating in Frames

Now you can do it with `data-turbo-action: "advance"`

### Turbo Drive: link_to format

```ruby
link_to "Upvote", upvote_post_path(post, choice: :upvote, format: :turbo_stream)
link_to "Upvote", upvote_post_path(post, choice: :upvote, format: :html)
```

### ViewComponents: use turbo-rails helpers:

To be able to access tags like `turbo_frame` or `turbo_stream` in a ViewComponent, you would need to include their helpers:

```ruby
# app/components/post_component.rb
include Turbo::FramesHelper
include Turbo::Streams::StreamName
include Turbo::Streams::Broadcasts
```

###

don’t use any globals in your partials - pass whatever they need in as locals so you can safely render them in different contexts

### Streams: `update` vs `replace`

### HOVERCARDS?!