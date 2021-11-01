---
layout: post
title: "Hotwire usecases. Part 3. Turbo frames OMG"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

### Turbo frame basics

* must have an id
* wraps around a div
* by default, when going to an URL from inside div, expects HTML response to have a turbo frame with same id
* content inside frame gets replaced by content from responce turbo frame
* lazy load from url if given `scr` property
* while being lazy loaded, can display some temporary content

### 1. Turbo Frames - Navigate between frames

source frame - go to link, find frame with same id, replace this content with target content

#app/views/static_pages/landing_page.html.erb
```ruby
<%= turbo_frame_tag 'feed' do %>
  Click to replace...
  <%= link_to 'Terms', terms_path %>
  <%= link_to 'Pricing', pricing_path %>
<% end %>
```

target frame - content from inside turbo_frame_tag will replace source frame

* if you click 'Terms'

#app/views/static_pages/terms.html.erb
```ruby
<%= turbo_frame_tag 'feed' do %>
  Renders Hello from terms
  <%= link_to 'Home', root_path %>
  <%= link_to 'Pricing', pricing_path %>
<% end %>
```

* if you click 'Pricing'

#app/views/static_pages/pricing.html.erb
```ruby
<%= turbo_frame_tag 'feed' do %>
  Renders Hello from pricing
  <%= link_to 'Home', root_path %>
  <%= link_to 'Terms', terms_path %>
<% end %>
```

### 2. Turbo frames - lazy load remote content

* lazy/eager load - as soon as content is loaded, `Loading...` will be replaced by target

#app/views/static_pages/landing_page.html.erb
```ruby
<%= turbo_frame_tag 'feed', src: terms_path, loading: :lazy do %>
  Loading...
<% end %>
```

### If navigation inside frame should not look for a frame with this ID - add `target: "_top"`
#app/views/static_pages/landing_page.html.erb
```ruby

  <%= turbo_frame_tag 'feed', src: inboxes_path do %>
    Loading inboxes
  <% end %>
```

****

### 7.1. Basic tabs with links inside the frame

* initial page - does not have to be present

#app/views/static_pages/landing_page.html.erb
```ruby
<%= turbo_frame_tag 'tabs' do %>
  <%= link_to 'Pricing', pricing_path %>
  <%= link_to 'Terms', terms_path %>
  <%= link_to 'Privacy', privacy_path %>
<% end %>
```

* 3 pages of tabbed content
* only what is inside `turbo_frame_tag` gets replaced

#app/views/static_pages/pricing.html.erb
```ruby
<%= turbo_frame_tag 'tabs' do %>
  <%= link_to_unless_current 'Pricing', pricing_path %>
  <%= link_to_unless_current 'Terms', terms_path %>
  <%= link_to_unless_current 'Privacy', privacy_path %>
  <h1>Pricing</h1>
  <p>Free</p>
<% end %>
```

#app/views/static_pages/terms.html.erb
```ruby
<%= turbo_frame_tag 'tabs' do %>
  <%= link_to_unless_current 'Pricing', pricing_path %>
  <%= link_to_unless_current 'Terms', terms_path %>
  <%= link_to_unless_current 'Privacy', privacy_path %>
  <h1>Terms</h1>
  <p>None</p>
<% end %>
```

****




AAAAA


<h1>StaticPages#landing_page</h1>
<p>Find me in app/views/static_pages/landing_page.html.erb</p>

<h1>Pricing</h1>

<%= link_to 'Target a frame on this page', pricing_path, data: { turbo_frame: 'monthly_pricing' } %>

<%= link_to 'Yearly', pricing_path, data: { turbo_frame: 'yearly_pricing' } %>
<hr>
<%= turbo_frame_tag 'monthly_pricing' do %>
  <%= link_to 'See monthly pricing', pricing_path %>
  <%= link_to 'Yearly', pricing_path, data: { turbo_frame: 'yearly_pricing' } %>
<% end %>
<hr>
<%= turbo_frame_tag 'yearly_pricing' do %>
  <%= link_to 'See yearly pricing', pricing_path %>
  <%= link_to 'Monthly', pricing_path, data: { turbo_frame: 'monthly_pricing' } %>
<% end %>

<hr>
<!-- 
  By default any link inside a frame will look for 
-->
<%= turbo_frame_tag 'monthly_pricing' do %>
  <%= link_to 'See monthly pricing', pricing_path %>
<% end %>

target="_top" - all links break out of turbo_frame_tag by default
data-turbo-frame="_self" - add this to the frame not to break out

* find yearly_pricing frame in pricing_path
* find yearly_pricing frame in current url
* replace yearly_pricing frame content in current url content from frame in yearly_pricing

<%= link_to 'Target any frame (Yearly pricing)', pricing_path, data: { turbo_frame: 'yearly_pricing' } %>


<%= turbo_frame_tag 'messages', target: '_top' do %>
  <%= link_to 'Break out of frame', message_path(1), data: { turbo_frame: '_top' } %>
  <%= link_to 'Stay in frame', message_path(1), data: { turbo_frame: '_self' } %>
<% end %>

<%= turbo_frame_tag 'messages' do %>
  <%= link_to 'Stay in frame', message_path(1) %>
  <%= link_to 'Break out of frame', message_path(1), data: { turbo_frame: '_top' } %>
  <%= link_to 'Target another frame', message_path(1), data: { turbo_frame: 'yearly_pricing' } %>
<% end %>
