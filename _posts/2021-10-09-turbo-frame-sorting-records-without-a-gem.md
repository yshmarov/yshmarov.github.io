---
layout: post
title: "#4 Turbo Frame - Sort records without page refresh. Sorting without a gem."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails request-params hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

![turbo frame sort withot any gems](/assets/images/turbo-sort-without-gem.gif)

### 1.1. Basic sorting functionality

* add helper to create sort_links that will pass search params
* add `data: { turbo_frame: 'search' }` to the links to act WITHIN a trubo frame `search`

#app/helpers/sort_helper.rb
```ruby
module SortHelper
  def sort_link(attribute, label = nil)
    attribute_or_label = label.presence || attribute.to_s.humanize
    @attribute = attribute
    link_to "#{icon} #{attribute_or_label}",
            url_for(controller: controller_name, action: action_name, @attribute => sort_direction),
            data: { turbo_frame: 'search' }
  end

  private

  def sort_direction
    case params[@attribute]
    when 'desc'
      'asc'
    when 'asc'
      'desc'
    else
      'desc'
    end
  end

  def icon
    case params[@attribute]
    when 'desc'
      '▼'
    when 'asc'
      '▲'
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

* Now you can add sort links
* If there is a current sort, there will be a link to "refresh"

#app/views/inboxes/index.html.erb
```ruby
<%= sort_link(:messages_count, 'Popular') %>
<%= sort_link(:created_at, 'Fresh') %>
<%= sort_link(:updated_at) %>
<%= link_back_if_params %>

<div id="inboxes">
  <%= render @inboxes %>
</div>
```

### 2. Turbo search

* Wrap search and inboxes into a `turbo_frame_tag` with the same ID as the sort links
* `target: '_top'` - not to break any other behavior inside the frame
* The helper for the sort links (`app/helpers/search_helper.rb`) should direct to the frame that you want to "refresh" with `data: { turbo_frame: 'search' }`

#app/views/inboxes/index.html.erb
```ruby
<%= turbo_frame_tag 'search', target: '_top' do %>

  <%= sort_link(:messages_count, 'Popular') %>
  <%= sort_link(:created_at, 'Fresh') %>
  <%= sort_link(:updated_at) %>
  <%= link_to 'Clear search', request.path if request.query_parameters.any? %>

  <div id="inboxes">
    <%= render @inboxes %>
  </div>
<% end %>
```
