---
layout: post
title: "Hotwire Turbo: Edit each attribute inline"
author: Yaroslav Shmarov
tags: ruby-on-rails-7 hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
youtube_id: bkFoYOMSlCU
---

Allow user to easily edit an attribute by just clicking on it!

This way you can have fewer full-page redirects; don't have to always render a full edit form.

![turbo inline edit fields](/assets/images/turbo-inline-edit-fields.gif)

5 years ago I would have used gem best_in_place for this, but now it can be easily achieved with turbo_frames!

List attributes that you want to be inline-editable

```ruby
# app/models/customer.rb
class Customer < ApplicationRecord
  INLINE_EDITABLE_ATTRS = [:first_name, :last_name, :dob, :tel, :description]

  validates :first_name, presence: true
end
```

Render each inline-editable field inside a separate `turbo_frame`. Redirect to the `edit_customer_path`. Pass the attribute in the url params `attribute: attribute`

```ruby
# app/views/customers/_customer.html.erb
<div id="<%= dom_id customer %>">
  <% Customer::INLINE_EDITABLE_ATTRS.each do |attribute| %>
    <%= turbo_frame_tag attribute do %>
    <p>
      <strong><%= attribute %>:</strong>
      <%= link_to (customer[attribute].presence || 'Edit'), [:edit, customer, attribute: attribute] %>
    </p>
    <% end %>
  <% end %>
</div>
```

Render the form with a **dynamicly-set** `turbo_frame` name. Render only the field with a matching name as `params[:attribute]`.

```ruby
# app/views/customers/_inline_attribute_form.html.erb
<%= turbo_frame_tag params[:attribute] do %>
  <%= form_with(model: customer, url: [customer, attribute: params[:attribute]], method: :patch) do |form| %>
    <% if customer.errors.any? %>
      <div style="color: red">
        <ul>
          <% customer.errors.each do |error| %>
            <li><%= error.full_message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <% if params[:attribute].eql? 'first_name' %>
      <div>
        <%= form.label :first_name, style: "display: block" %>
        <%= form.text_field :first_name, onchange: 'this.form.requestSubmit()' %>
      </div>
    <% end %>

    <% if params[:attribute].eql? 'last_name' %>
      <div>
        <%= form.label :last_name, style: "display: block" %>
        <%= form.text_field :last_name, onchange: 'this.form.requestSubmit()' %>
      </div>
    <% end %>

    <% if params[:attribute].eql? 'dob' %>
      <div>
        <%= form.label :dob, style: "display: block" %>
        <%= form.datetime_field :dob, onchange: 'this.form.requestSubmit()' %>
      </div>
    <% end %>

    <% if params[:attribute].eql? 'tel' %>
      <div>
        <%= form.label :tel, style: "display: block" %>
        <%= form.number_field :tel, onchange: 'this.form.requestSubmit()' %>
      </div>
    <% end %>

    <% if params[:attribute].eql? 'description' %>
      <div>
        <%= form.label :description, style: "display: block" %>
        <%= form.text_area :description, onchange: 'this.form.requestSubmit()' %>
      </div>
    <% end %>

    <div>
      <%= form.submit %>
    </div>
  <% end %>
<% end %>
```

Finally, you can use both the attribute-edit form and the normal form. Just render the normal fomr if no `params[:attribute]` is present:

```ruby
# app/views/customers/edit.html.erb
<% if params[:attribute].present? %>
  <%= render "inline_attribute_form", customer: @customer %>
<% else %>
  <%= render "form", customer: @customer %>
<% end %>
```

That's it! 🎉🥳🍾
