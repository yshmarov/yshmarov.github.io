---
layout: post
title: "Turbo Frame - Sort records without page refresh. Sorting without a gem."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails request-params hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

![turbo frame sort withot any gems](/assets/images/turbo-sort-without-gem.gif)

### 1. Basic sorting for records

##### 1.1. URL params are mighty! Use them! Some helpers:

* see all params that are applied to current URL

```ruby
<%= params %>
```

* controller and action params are always present in a request
* hacky way to see if any OTHER params are present:

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

##### 1.2. Add sorting

* add helper to create sort_links that will pass search params
* add `data: { turbo_frame: 'search' }` to the links to act WITHIN a trubo frame `search`

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

### 2. Turbo search

* Wrap search and inboxes into a `turbo_frame_tag` with the same ID as the sort links
* `target: '_top'` - not to break any other behavior inside the frame
* The helper for the sort links (`app/helpers/search_helper.rb`) should direct to the frame that you want to "refresh" with `data: { turbo_frame: 'search' }`

#app/views/inboxes/index.html.erb
```ruby

<%= turbo_frame_tag 'search', target: '_top' do %>

  <%= sort_link(:messages_count) %>
  <%= sort_link(:created_at) %>
  <%= link_back_if_params %>

  <div id="inboxes">
    <%= render @inboxes %>
  </div>
<% end %>
```
