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

* display the value of a param (if present)

```ruby
params[:messages_count].presence
```

### Sorting records

* add helper to create sort_links that will pass search params

#app/helpers/search_helper.rb
```ruby
module SearchHelper
  def sort_link(attribute)
    @attribute = attribute
    if params[attribute].eql?('desc')
      link_to "▼ #{attribute.to_s.humanize}",
              url_for(controller: controller_name, action: action_name, @attribute => :asc),
              data: { turbo_frame: 'search' }
    elsif params[attribute].eql?('asc')
      link_to "▲ #{attribute.to_s.humanize}",
              url_for(controller: controller_name, action: action_name, @attribute => :desc),
              data: { turbo_frame: 'search' }
    elsif !params.key?(attribute)
      link_to attribute.to_s.humanize,
              url_for(controller: controller_name, action: action_name, @attribute => :asc),
              data: { turbo_frame: 'search' }
    end
  end

  def link_back_if_params
    if (params.keys - ['controller'] - ['action']).present?
      link_to 'Clear filters',
              url_for(controller: controller_name, action: action_name),
              data: { turbo_frame: 'search' }
    end
  end
end
```

* Override collection based on params from request

#app/controllers/inboxes_controller.rb
```ruby
  def index
    @search_param = params.keys - ['controller'] - ['action']
    @search_param = @search_param[0]
    @inboxes = if params[@search_param].present?
                 Inbox.order(@search_param => params[@search_param])
               else
                 Inbox.order(created_at: :desc)
               end
  end
```

* Link to same index page, but with some params, with all the conditional views:

#app/views/inboxes/index.html.erb
```ruby

<%= sort_link(:messages_count) %>
<%= sort_link(:created_at) %>
<%= link_back_if_params %>

<div id="inboxes">
  <%= render @inboxes %>
</div>
```

### Surely, this approach can be improved a lot, but works well for something simple.
