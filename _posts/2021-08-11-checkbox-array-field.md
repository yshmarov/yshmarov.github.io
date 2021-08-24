---
layout: post
title: "Boolean Checkbox array - easier than you think!"
author: Yaroslav Shmarov
gdpr: ruby rails ruby-on-rails checkboxes array
thumbnail: /assets/thumbnails/checkboxes.png
---

Easy way to edit and persist an array of pre-defined booleans as a string.

## Final result:

![checkbox array](/assets/images/checkbox-array.png)

## HOWTO:

db/migrate/20210813135727_add_gdpr_to_clients.rb

```ruby
class AddGdprToClients < ActiveRecord::Migration
  def change
    # add_column :clients, :gdpr, :string, null: true, array: true
    add_column :clients, :gdpr, :string, array: true, default: []
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
  <%= form.check_box :gdpr, { multiple: true, checked: form.object.gdpr&.include?(key.to_s) }, key, nil %>
  <%= form.label key %>
<% end %>
```

app/views/clients/show.html.haml

```ruby
<%= @client.gdpr&.to_sentence %>

# or

<% @client.gdpr&.each do |item| %>
  <%= item.humanize %>
<% end %>
```

****

add to array:

```ruby
post.gdpr << 'face_recognition'

# or
post.gdpr.push 'face_recognition'

# or
post.gdpr += ['face_recognition']
```

scopes:

```ruby
# This is valid
Post.where("'face_recognition' = ANY (gdpr)")

# This is more secure
Post.where(":gdpr = ANY (gdpr)", gdpr: 'face_recognition')

# This is also valid
Post.where("gdpr @> ?", "{face_recognition}")

# This is valid
Post.where("gdpr @> ARRAY[?]::varchar[]", ["face_recognition", "geodata"])

# This is valid
Post.where("gdpr &&  ?", "{face_recognition,geodata}")

# %oda% is geODAta
Post.where("array_to_string(gdpr, '||') LIKE :gdpr", gdpr: "%oda%")
```
