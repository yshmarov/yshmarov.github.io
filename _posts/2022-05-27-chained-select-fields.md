---
layout: post
title: "Chained select fields for custom data structures"
author: Yaroslav Shmarov
tags: ruby-on-rails hotwire turbo chained-select
thumbnail: /assets/thumbnails/turbo.png
---

In this post I want to demonstrate:
* defining data structures in a model
* adding conditional `validations`
* displaying `select` fields in a form

### TWO chained fields

**Mission: Select car brand and model**

![2-chained-fields-car-select.gif](/assets/images/2-chained-fields-car-select.gif)

```shell
rails g scaffold cars brand model description:text
```

Define collections and validations:

```ruby
# app/models/car.rb
class Car < ApplicationRecord
  # 2 levels of data. sometimes level 2 can be blank.
  CARS = { audi: %w[a1 a2 a3 a4 a5 a6 s8],
           kia: %w[ceed sportage],
           tesla: ['model x', 'model 3'],
           nissan: [],
           bmw: %w[i3 s8] }.freeze

  validates :description, presence: true
  validates :brand, presence: true

  # sportage can not be in bmw
  validates :model, inclusion: { in: ->(record) { record.models }, allow_blank: true }
  # nissan should have no model
  validates :model, presence: { if: ->(record) { record.models.present? } }

  def brands
    CARS.keys
  end

  def models
    return [] unless brand.present?

    CARS[brand.to_sym] || []
  end
end
```

Select fields in form:

```ruby
# app/views/addresses/_form.html.erb
<%= form_with(model: car) do |form| %>
  <%= form.select :brand, car.brands %>
  <%= form.select :model, car.models %>
  <%= form.text_area :description %>
  <%= form.submit %>
<% end %>
```

### THREE chained fields

**Mission: Select address country, region, city**

![3-chained-fields-address-select](/assets/images/3-chained-fields-address-select.gif)

```shell
rails g scaffold address country region city description:text
```

Define collections and validations:

```ruby
# app/models/address.rb
  #  3 levels of data. sometimes level 2 or level 3 can be blank
  CS3 = { us:
            { california: ['sacramento', 'los angeles'],
              maryland: %w[annapolis baltimore] },
          de: { bayern: {}, turingen: {} },
          pl: {},
          ua:
            { north: %w[chernihiv kyiv],
              west: %w[lviv bukovel] } }.freeze

  validates :description, presence: true
  validates :country, presence: true

  # california can not be in de
  validates :region, inclusion: { in: ->(record) { record.regions.map(&:to_s) }, allow_blank: true }
  # pl should have no region
  validates :region, presence: { if: ->(record) { record.regions.present? } }

  # sacramento can not be in bayern
  validates :city, inclusion: { in: ->(record) { record.cities }, allow_blank: true }
  # de should have no city
  validates :city, presence: { if: ->(record) { record.cities.present? } }

  def countries
    CS3.keys
  end

  def regions
    return [] unless country.present?

    CS3[country.to_sym].keys || []
  end

  def cities
    return [] unless country.present? && region.present?

    CS3[country.to_sym][region.to_sym] || []
  end
```

Select fields in form:

```ruby
# app/views/addresses/_form.html.erb
<%= form_with(model: address) do |form| %>
    <%= form.select :country, address.countries %>
    <%= form.select :region, address.regions %>
    <%= form.select :city, address.cities.map { | k, v | [k.capitalize, k] } %>
    <%= form.text_area :description %>
    <%= form.submit %>
<% end %>
```

Now when your backend is solid, feel free to add some interactivity to your form with Hotwire.