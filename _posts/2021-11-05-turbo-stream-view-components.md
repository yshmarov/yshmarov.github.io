---
layout: post
title: "#13 Turbo Streams: 5 ways to render View Components"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo viewcomponent
thumbnail: /assets/thumbnails/turbo.png
---

If you have problems rendering a ViewComponent with Turbo Streams, here are some solutions.

### 4 ways to do it in a controller:

```ruby
render_to_string(PaginationComponent.new(results: @results))
view_context.render(PaginationComponent.new(results: @results))
PaginationComponent.new(results: @results).render_in(view_context)
# most universal:
ApplicationController.render(PaginationComponent.new(results: @results), layout: false)
```

All work, use either one with Turbo Streams:

```ruby
# app/controllers/hello_controller.rb
def some_action
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        # turbo_stream.update('inboxes-pagination', render_to_string(PaginationComponent.new(results: @results))),
        # turbo_stream.update("inboxes-pagination", view_context.render(PaginationComponent.new(results: @results))),
        turbo_stream.update("inboxes-pagination", PaginationComponent.new(results: @results).render_in(view_context))
      ]
    end
  end
end
```

### Our just use a `some_action.turbo_stream.erb` template:

```ruby
# app/controllers/hello_controller.rb
def some_action
  respond_to do |format|
    format.turbo_stream
  end
end
```

```ruby
# index.turbo_stream.erb
<%= turbo_stream.update "inventory-pagination" do %>
  <%= render PaginationComponent.new(results: @results) %>
<% end %>
```

That's it!
