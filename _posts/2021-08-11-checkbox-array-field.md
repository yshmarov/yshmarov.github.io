---
layout: post
title: "Boolean Checkbox array - easier than you think!"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails checkboxes array
thumbnail: /assets/thumbnails/checkboxes.png
---

Easy way to edit and persist an array of pre-defined booleans as a string.

## Final result:

![checkbox array](/assets/images/checkbox-array.png)

## HOWTO:

db/migrate/20210813135727_add_gdpr_to_clients.rb
```ruby
class AddGdprToClients < ActiveRecord::Migration[5.2]
  def change
    add_column :clients, :gdpr, :string, null: true, array: true
  end
end
```

app/controllers/clients_controller.rb
```ruby
  def client_params
    params.require(:client).permit(:first_name, :last_name, gdpr: [])
  end
```
app/models/client.rb
```ruby
  GDPRS = [:analyze_data, :take_photos, :publish_photos]
```
app/views/clients/_form.html.haml
```ruby
<% Client::GDPRS.each do |key, value| %>
  <%= f.check_box :gdpr, { multiple: true, checked: f.object.gdpr&.include?(key.to_s) }, key, nil %>
  <%= f.label "gdpr_#{key}", value %>
```
app/views/clients/show.html.haml
```ruby
<%= @client.gdpr&.to_sentence %>

# or

<% @client.gdpr&.each do |item| %>
  <%= item.humanize %>
<% end %>
```
