---
layout: post
title: "Sorting records without a gem. Request params"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails request-params
thumbnail: /assets/thumbnails/url.png
---

### URL params are mighty! Use them! Some helpers:

* see all params

```ruby
<%= params %>
```

* controller and action params are always present in a request
* hacky way to see if any OTHER params are present

```ruby
(params.keys - ['controller'] - ['action']).present?
```

* see if a particular params is present

```ruby
params.key?(:messages_count)
```

* display the value of a param

```ruby
params[:messages_count]
```

### Sorting records

* Link to same index page, but with some params, with all the conditional views:

#app/views/inboxes/index.html.erb
```ruby

<% unless params.key?(:messages_count) %>
  <%= link_to '▼ Message count', inboxes_path(messages_count: :desc) %>
<% end %>
<% if params[:messages_count].eql?('desc') %>
  ▼
  <%= link_to '▲ Message count', inboxes_path(messages_count: :asc) %>
<% elsif params[:messages_count].eql?('asc') %>
  ▲
  <%= link_to '▼ Message count', inboxes_path(messages_count: :desc) %>
<% end %>
<% if (params.keys - ['controller'] - ['action']).present? %>
  <%= link_to 'Clear filters', inboxes_path %>
<% end %>

<div id="inboxes">
  <%= render @inboxes %>
</div>
```

* Override collection based on params from request

#app/controllers/inboxes_controller.rb
```ruby
  def index
    # @inboxes = Inbox.order(created_at: :desc)
    if params[:messages_count].present?
      @inboxes = Inbox.order(messages_count: params[:messages_count].to_sym)
    else
      @inboxes = Inbox.order(created_at: :desc)
    end
  end
```

* same as above, with better code style:

```ruby
  def index
    # @inboxes = Inbox.order(created_at: :desc)
    @inboxes = if params[:messages_count].present?
                 Inbox.order(messages_count: params[:messages_count].to_sym)
               else
                 Inbox.order(created_at: :desc)
               end
  end
```

### Surely, this approach can be improved a lot, but works well for something simple.
