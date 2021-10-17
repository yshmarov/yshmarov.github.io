---
layout: post
title: "#7 Hotwire Turbo: Search without page refresh. Stimulus and Turbo Frames."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

Search without page refresh using Hotwire (Turbo Frames & Stimulus):
![hotwire-turbo-search](/assets/images/turbo-search.gif)

### HOWTO:

* case-insensitive search, like [in this post](https://blog.corsego.com/ruby-on-rails-search-field-without-gems)
* `@search_params` - there is no page refresh, but you might want to access the search URL

#app/controllers/inboxes_controller.rb
```ruby
  def index
		@search_params = request.url
		if params[:name].present?
		  @inboxes = Inbox.where('name ilike ?', "%#{params[:name]}%")
		else
		  @inboxes = Inbox.all
		end
  end
```

* stimulus controller to submit form with 500ms delay, [inspired by David Colby's post](https://www.colby.so/posts/filtering-tables-with-rails-and-hotwire)

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

* initialize stimulus controller
* stimulus target - this form
* on input - fire the stimulus controller to submit this form
* on submit - target `turbo_frame: 'search'` with list of inboxes
* wrap list of inboxes into a `turbo_frame_tag 'search'`

#app/views/inboxes/index.html.erb
```ruby
<%= form_with url: inboxes_path,
						  method: :get,
						  data: { controller: 'search-form',
										  search_form_target: 'form',
										  turbo_frame: 'search' } do |form| %>
  <%= form.text_field :name,
										  placeholder: 'Name',
										  value: params[:name],
										  autocomplete: 'off',
										  autofocus: true,
										  data: { action: 'input->search-form#search' } %>
<% end %>

<%= turbo_frame_tag 'search' do %>
	<div id="inboxes">
	  <%= render @inboxes %>
	</div>
<% end %>
```

### consideration:

* you might want to use `target: '_top'` on such a "global" turbo_frame, so that when you click a link inside the frame, it does not look for a `turbo_frame_tag "search"`
```diff
-- <%= turbo_frame_tag 'search' do %>
++ <%= turbo_frame_tag 'search', target: '_top' do %>
```
