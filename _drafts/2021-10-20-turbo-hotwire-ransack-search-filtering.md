---
layout: post
title: "#8 Turbo Frames - Search and Filtering with gem Ransack"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails ransack hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---


* initial setup

```sh
rails g scaffold inbox name
rails db:migrate
rails c
5.times { Inbox.create(name: SecureRandom.hex) }
rails s
```

* add ransack

```ruby
#Gemfile
gem 'ransack', github: 'activerecord-hackery/ransack'
```

```ruby
#app/controllers/inboxes_controller.rb
  def index
    @q = Inbox.ransack(params[:q])
    @inboxes = @q.result(distinct: true)
  end
```

### 1. search and sorting without turbo

```ruby
<%= search_form_for @q do |f| %>
  <%= f.label :name_cont %>
  <%= f.search_field :name_cont %>
  <%= f.submit %>
<% end %>

<%= sort_link @q, :messages_count, 'Popular' %>
<%= sort_link @q, :created_at, 'Fresh' %>

<%= link_to 'Clear search', request.path if request.query_parameters.any? %>

<div id="inboxes">
  <%= render @inboxes %>
</div>
```

* ADD TURBO:
* wrap the results AND the search/sort into a frame
* search/sort should be in the frame so that the search query & sort direction gets updated
* target_top - explicitly target what you need by the frame
* the search links should have a turbo_frame 'search' target

```ruby
<%= turbo_frame_tag 'search', target: "_top" do %>

  <%= search_form_for @q, data: { turbo_frame: 'search'} do |f| %>
    <%= f.label :name_cont %>
    <%= f.search_field :name_cont %>
    <%= f.submit %>
  <% end %>

  <%= sort_link @q, :messages_count, 'Popular', {}, { data: { turbo_frame: 'search'} } %>
  <%= sort_link @q, :created_at, 'Fresh', {}, { data: { turbo_frame: 'search'} } %>

  <%= link_to 'Clear search', request.path, data: { turbo_frame: 'search'} if request.query_parameters.any? %>

  <div id="inboxes">
    <%= render @inboxes %>
  </div>
<% end %>
```

### 2. autosubmit search field

#app/javascript/controllers/search_form_controller.js
```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form" ]

  connect() { console.log("search form connected") }

  search() {
  clearTimeout(this.timeout)
  this.timeout = setTimeout(() => {
    // This needs a polyfill for Safari and IE11 support. Alternatively, use Rails/ujs:
    // Rails.fire(this.formTarget, 'submit')
    this.formTarget.requestSubmit()
  }, 500)
  }
}
```

* if search form stays in turbo_frame:
a) the stimulus contorller will re-initialize each time
b) ??
* move the search form out of turbo frame tag

* TODO: if search_form is not in the turbo_frame, clear_search does not clear the input field

```ruby
<%= search_form_for @q, data: { controller: 'search-form',
                                search_form_target: 'form',
                                turbo_frame: 'search' } do |f| %>
  <%= f.label :name_cont %>
  <%= f.search_field :name_cont,
                     autocomplete: "off",
                     data: { action: "input->search-form#search" } %>
  <%= f.submit %>
<% end %>

<%= turbo_frame_tag 'search', target: "_top" do %>
  <%= sort_link @q, :messages_count, 'Popular', {}, { data: { turbo_frame: 'search'} } %>
  <%= sort_link @q, :created_at, 'Fresh', {}, { data: { turbo_frame: 'search'} } %>

  <%= link_to 'Clear search', request.path, data: { turbo_frame: 'search'} if request.query_parameters.any? %>

  <div id="inboxes">
    <%= render @inboxes %>
  </div>
<% end %>
```


https://gist.github.com/mrmartineau/a4b7dfc22dc8312f521b42bb3c9a7c1e
https://stimulus.hotwired.dev/reference/targets
    // this.fieldTarget.value = '';
