---
layout: post
title: "#7 Hotwire Turbo Frames: Search without page refresh. Stimulus. Ransack"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo ransack stimulus
thumbnail: /assets/thumbnails/turbo.png
---

Search without page refresh using Hotwire (Turbo Frames & Stimulus):
![hotwire-turbo-search](/assets/images/turbo-search.gif)

### 0. Initial setup

```sh
rails g scaffold inbox name
rails db:migrate
rails c
5.times { Inbox.create(name: SecureRandom.hex) }
rails s
```

### 1. Without Ransack

* case-insensitive search, like [in this post](https://blog.corsego.com/ruby-on-rails-search-field-without-gems)

#app/controllers/inboxes_controller.rb
```ruby
  def index
    if params[:name].present?
      @inboxes = Inbox.where('name ilike ?', "%#{params[:name]}%")
    else
      @inboxes = Inbox.all
    end
  end
```

* stimulus controller to submit form with 500ms delay, [inspired by this post](https://www.colby.so/posts/filtering-tables-with-rails-and-hotwire)

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

* initialize stimulus controller on form
* stimulus target - this form
* on input - fire the stimulus controller to submit this form
* form target - `turbo_frame: 'search'` with list of inboxes
* wrap list of inboxes into a `turbo_frame_tag 'search'`

```ruby
#app/views/inboxes/index.html.erb
<%= form_with url: inboxes_path,
              method: :get,
              data: { controller: 'debounce',
                      debounce_target: 'form',
                      turbo_frame: 'search' } do |form| %>
  <%= form.text_field :name,
                      placeholder: 'Name',
                      value: params[:name],
                      autocomplete: 'off',
                      autofocus: true,
                      data: { action: 'input->debounce#search' } %>
<% end %>

<%= turbo_frame_tag 'search' do %>
  <%= request.url %>
  <%= link_to 'Clear search', request.path if request.query_parameters.any? %>
  <div id="inboxes">
    <%= render @inboxes %>
  </div>
<% end %>
```

* Next, you **will** want to use `target: '_top'` on such a "global" turbo_frame, so that when you click a link on content inside the frame, it does not look for a `turbo_frame_tag "search"`

```diff
#app/views/inboxes/index.html.erb
-- <%= turbo_frame_tag 'search' do %>
++ <%= turbo_frame_tag 'search', target: '_top' do %>
-- <%= link_to 'Clear search', request.path if request.query_parameters.any? %>
++ <%= link_to 'Clear search', request.path, data: { turbo_frame: 'search'} if request.query_parameters.any? %>
```

### 2. With Ransack

**Basic search without Turbo:**

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

```diff
#app/views/inboxes/index.html.erb
++<%= search_form_for @q do |f| %>
++  <%= f.label :name_cont %>
++  <%= f.search_field :name_cont %>
++  <%= f.submit %>
++<% end %>

++<%= sort_link @q, :messages_count, 'Popular' %>
++<%= sort_link @q, :created_at, 'Fresh' %>

++<%= link_to 'Clear search', request.path if request.query_parameters.any? %>

<div id="inboxes">
  <%= render @inboxes %>
</div>
```

### 2.1. ADD TURBO

* wrap the results into a frame
* search/sort should be in the frame - so that the sort direction images get updated
* `target: "_top"` - explicitly target what you need by the frame
* the search links should have a turbo_frame 'search' target
* connect the stimulus controller to the FORM
* stimulus - submit `search_field` on INBPUT

```diff
#app/views/inboxes/index.html.erb
--<%= search_form_for @q, data: { turbo_frame: 'search'} do |f| %>
++<%= search_form_for @q, data: { controller: 'debounce',
++                                debounce_target: 'form',
++                                turbo_frame: 'search' } do |f| %>
    <%= f.label :name_cont %>
--  <%= f.search_field :name_cont %>
++  <%= f.search_field :name_cont,
++                     autocomplete: "off",
++                     data: { action: "input->debounce#search" } %>
    <%= f.submit %>
  <% end %>

++<%= turbo_frame_tag 'search', target: "_top" do %>
--<%= sort_link @q, :messages_count, 'Popular' %>
--<%= sort_link @q, :created_at, 'Fresh' %>
++<%= sort_link @q, :messages_count, 'Popular', {}, { data: { turbo_frame: 'search'} } %>
++<%= sort_link @q, :created_at, 'Fresh', {}, { data: { turbo_frame: 'search'} } %>

  <%= link_to 'Clear search', request.path, data: { turbo_frame: 'search'} if request.query_parameters.any? %>

  <!-- request.url - to see the URL returned by the turbo_frame -->
  <%= request.url %>

  <div id="inboxes">
    <%= render @inboxes %>
  </div>
++<% end %>
```

### 2.2. Reset search

* currently, if search_form is not in the turbo_frame, clear_search does not clear the input field
* add a stimulus controller to **"click a button -> reset an input field"**

#app/javascript/controllers/reset_controller.js
```js
import { Controller } from "@hotwired/stimulus"

//<div data-controller="reset">
//  <input data-reset-target=clearme>
//  <button data-action="click->reset#clean">clear</button>
//</div>

export default class extends Controller {
  static targets = [ "clearme" ]

  connect() { console.log("reset controller connected") }

  clean() {
    console.log(this.clearmeTarget)
    this.clearmeTarget.value=''
  }
}
```

* wrap the content into the new controller: `<div data-controller="reset">`
* add a target to the input field that should be reset: `data: { reset_target: 'clearme',`
* add an action to the button that should reset the input: `action: "click->reset#clean"`

```diff
++<div data-controller="reset">
<%= search_form_for @q, data: { controller: 'debounce',
                                debounce_target: 'form',
                                turbo_frame: 'search' } do |f| %>
  <%= f.label :name_cont %>
  <%= f.search_field :name_cont,
                     autocomplete: "off",
++                     data: { reset_target: 'clearme', 
                     action: "input->debounce#search" } %>
  <%= f.submit %>
<% end %>

<%= turbo_frame_tag 'search', target: "_top" do %>
  <%= sort_link @q, :messages_count, 'Popular', {}, { data: { turbo_frame: 'search'} } %>
  <%= sort_link @q, :created_at, 'Fresh', {}, { data: { turbo_frame: 'search'} } %>

--<%= link_to 'Clear search', request.path, data: { turbo_frame: 'search'} if request.query_parameters.any? %>
++<%= link_to 'Clear search', request.path, data: { action: "click->reset#clean", turbo_frame: 'search'} if request.query_parameters.any? %>

  <!-- request.url - to see the URL returned by the turbo_frame -->
  <%= request.url %>

  <div id="inboxes">
    <%= render @inboxes %>
  </div>
<% end %>
++</div>
```

PERFECTO!!!

However...

A BIG DRAWBACK of this approach = this way we do not update the URL on search.

How can we do it? Turbo Drive? Some js? Who knows...
