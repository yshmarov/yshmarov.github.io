---
layout: post
title: "#13 Turbo Streams: 4 ways to render View Components"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo viewcomponent
thumbnail: /assets/thumbnails/turbo.png
---

### 3 ways to do it in a controller:

All work, use either one:

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
