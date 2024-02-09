---
layout: post
title: "Chained select fields for gem City-State"
author: Yaroslav Shmarov
tags: ruby-on-rails hotwire turbo city-state chained-select
thumbnail: /assets/thumbnails/numbered-list.png
youtube_id: vKjWXMHzOoA
---

[Gem City-State](https://github.com/loureirorg/city-state/){:target="blank"} is a great library of relationships between countries-states-cities.
Thanks this gem you don't need to resort to using some sort of external API like Google Maps for most basic usecases.

![city-state-gem-dynamic-select.gif](/assets/images/city-state-gem-dynamic-select.gif)

However, when adding this gem you will encounter a **classic** problem of:
1. selecting `state` based on `country`
2. selecting `city` based on `state`

Good `validations` are most important to making this work.

You want to make it impossible to save an invalid country-state-city combination.
Something like `country: "Ukraine, city: "New York` should be invalid. Oops, there actually exists a city [New York, Ukraine](https://en.wikipedia.org/wiki/New_York_(Ukraine)){:target="blank"}😜

### 1. Basic setup

```shell
bundle add city-state
rails g scaffold address country state city address_line_1
rails db:migrate
```

You need to validate that:
* a selected `state` belongs to a selected `country`;
* `city` belongs to a selected `country-state` combination.

Also, condider that some countries don't have states or cities (Vatican, Antarctica), so you should not validate presence of a `city` and `state` for them.

```ruby
# app/models/address.rb
class Address < ApplicationRecord
  validates :country, presence: true
  validates :address_line_1, presence: true

  # state has to be valid when changing a country
  validates :state, inclusion: { in: ->(record) { record.state_opts.keys }, allow_blank: true }
  validates :state, presence: { if: ->(record) { record.state_opts.present? } }

  # some countries don't have any cities, like Vatican.
  # city has to be valid when changing a country/state
  validates :city, inclusion: { in: ->(record) { record.city_opts }, allow_blank: true }
  validates :city, presence: { if: ->(record) { record.city_opts.present? } }

  def country_opts
    CS.countries.with_indifferent_access
  end

  def state_opts
    CS.states(country).with_indifferent_access
  end

  def city_opts
    CS.cities(state, country) || []
  end

  def country_name
    country_opts[country]
  end

  def state_name
    state_opts[state]
  end
end
```

Now, the form can look like this:

```ruby
# app/views/addresses/_form.html.erb
<%= form_with(model: address) do |form| %>
  <%= form.label :country, style: "display: block" %>
  <%= form.select :country, address.country_opts.invert, {include_blank: true}, { onchange: "this.form.requestSubmit();" } %>

  <%= form.label :state, style: "display: block" %>
  <%= form.select :state, address.state_opts.invert, {include_blank: true}, { onchange: "this.form.requestSubmit();" } %>

  <%= form.label :city, style: "display: block" %>
  <%= form.select :city, address.city_opts, {include_blank: true}, {} %>

  <%= form.submit %>
<% end %>
```

However, this way there is a full page refresh each time you select something.

Let's improve it.

### 2. Dynamic form

```shell
rails g stimulus form-reset
rails g stimulus form-element
```

To fix a common problem of refreshing the page and still having values in a form:

```js
// app/javascript/controllers/form_reset_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  connect() {
    this.element.reset()
  }
}
```

Considering the learning from the previous post, we will add a stimulus controller that will help us to submit a "remote" button:

```js
// app/javascript/controllers/form_element_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  static targets = ["submitbtn"]

  connect() {
    this.submitbtnTarget.hidden = true
  }

  autosumbit() {
    this.submitbtnTarget.click()
  }
}
```

and in the controller we need to allow passing `address_params` in the `new` action:

```diff
# app/controllers/addresses_controller.rb
  def new
-    @address = Address.new
+    @address = Address.new address_params
  end

  def address_params
-    params.require(:address).permit(:country, :city, :state, :address_line_1)
+    params.fetch(:address, {}).permit(:country, :city, :state, :address_line_1)
  end
```

Finally, we will update our form:
* add a turbo_frame for the part of content that will be reloaded
* add a button to refresh the turbo_frame when `country` or `state` is selected

```ruby
# app/views/addresses/_form.html.erb
<%= form_with(model: address, data: {controller: "form-reset"}) do |form| %>
  <div data-controller="form-element">
    <%= form.button "Validate", formaction: new_address_path, formmethod: :get, data: {form_element_target: "submitbtn", turbo_frame: :dynamic_fields} %>
    <%= turbo_frame_tag :dynamic_fields do %>
      <%= form.label :country, style: "display: block" %>
      <%= form.select :country, CS.countries.invert, {include_blank: true}, {data: { action: "change->form-element#autosumbit"}} %>

      <%= form.label :state, style: "display: block" %>
      <%= form.select :state, address.state_opts.invert, {include_blank: true}, {data: { action: "change->form-element#autosumbit"}} %>

      <%= form.label :city, style: "display: block" %>
      <%= form.select :city, address.city_opts, {include_blank: true}, {} %>
    <% end %>
  </div>
  <%= form.submit %>
<% end %>
```

That's it!

Now your dynamic select should work perfectly:
![city-state-gem-dynamic-select.gif](/assets/images/city-state-gem-dynamic-select.gif)
