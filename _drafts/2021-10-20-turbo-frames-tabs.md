---
layout: post
title: "#7 Turbo Frames - easy way to create tabs"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo tabs
thumbnail: /assets/thumbnails/turbo.png
---

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
