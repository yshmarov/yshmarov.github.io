---
layout: post
title: "gem MapkickJS for beautiful JavaScript maps with one line of Ruby"
author: Yaroslav Shmarov
tags: ruby rails mapkick
thumbnail: /assets/thumbnails/map-marker.png
---

[MapkickJS](https://github.com/ankane/mapkick.js){:target="blank"} is a javascript adapter to display coordinates on Mapbox maps. It requires a [Mapbox API key](https://account.mapbox.com/auth/signup/){:target="blank"}.

[mapkick-rb](https://github.com/ankane/mapkick){:target="blank"} is a Ruby on Rails adapter for MapkickJS. It allows you to easily feed a JSON with **coordinates** and display a map within your Rails app.

To display a marker on a map, you need to know **latitude** and **longitude** GPS coordinates. [gem Geocoder]({ post_url 2023-01-22-gem-geocoder-ruby }) allows you to get **coordinates** based on an **address** (house, street, city, state, country).

### Basic usage

After installing the gem, initialize your Mapkick API key.

```ruby
# echo > config/initializers/mapbox.rb
# config/initializers/mapbox.rb
ENV["MAPBOX_ACCESS_TOKEN"] = "pk.eyJ1..."
# ENV["MAPBOX_ACCESS_TOKEN"] = Rails.application.credentials.dig(:mapkick_api_key)
```

Basic map with multiple options:

```ruby
<%= js_map [{latitude: 37.7829,
             longitude: -122.4190,
             label: 'My home',
             tooltip: 'Hello!'
            }],
            id: "cities-map",
            width: "800px",
            height: "500px",
            markers: {color: "#00FF00"},
            tooltips: { hover: false, html: true},
            style: "mapbox://styles/mapbox/outdoors-v12",
            zoom: 15,
            controls: true,
            refresh: 60 %>
```

Result - display a marker on draggable map:

![mapbox-map-all-params](/assets/images/mapbox-map-all-params.png)

### HTML tooltips

Create a helper with a link to the `location` page:

```ruby
# app/helpers/locations_helper.rb
module LocationsHelper
  def html_link_to_location(location)
    link_to location.name,
            location_url(location),
            target: '_blank',
            style: 'font-weight: bold; color: green'
  end
end
```

To be able to click on the tooltip, use the option `{ hover: false, html: true}`.

Render the helper method in the tooltip param:

```ruby
<%= js_map [{latitude: location.latitude,
             longitude: location.longitude,
             label: location.name,
             tooltip: html_link_to_location(location)}],
             tooltips: { hover: false, html: true} %>
```

Result - map with clickable links to locations:

![mapbox-map-clickable-link](/assets/images/mapbox-map-clickable-link.png)

### Display multiple locations on the map, JSON

For this, the best way will be to render `/locations.json`:

```ruby
<%= js_map locations_path(format: :json) %>
```

Customize the JSON:

```json
// app/views/locations/_location.json.jbuilder
json.extract! location, :latitude, :longitude
json.label location.name
json.tooltip html_link_to_location(location)
// json.tooltip "#{html_link_to_location(location)} <br> #{location.address}"
```

Result - `@locations` is rendered from `app/views/locations/index.json.jbuilder`:

![mapbox-map-multiple-locations](/assets/images/mapbox-map-multiple-locations.png)

### JSON with search params

In this final example, we will factor in having a search form for `place` and `distance`:

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  before_action :set_location, only: %i[ show edit update destroy ]

  # GET /locations or /locations.json
  def index
    if params[:place].present?
      @locations = Location.near(params[:place], params[:distance] || 10, order: :distance)
      # distance 10 km => zoom 13x; distance 100 km => zoom 10x;
      # @zoom = params[:distance].eql?('10') ? 13 : 10
    else
      @locations = Location.all
    end
    respond_to do |format|
      format.html
      format.json
    end
  end
```

Be sure to add the query params to the path in the view:

```ruby
<%= js_map locations_path(format: :json, place: params[:place], distance: params[:distance]), zoom: @zoom %>
```

Result - show only location within set `distance` from geocoded coordinates of `place`:

![geocoder-search-zoom](/assets/images/geocoder-search-zoom.gif)

### Bonus: Search for locations that offer a specific product

Business problem #1: Find *hotels* that have a *SPA*

Business problem #2: Find *hotels* that have a *Massage*

Here we are solving the problem: *"find all parents with children that have a particular attribute"*.

In the below example `location has_many :products` && `Product.name = String`.

Add `product_name` search field:

```ruby
<%= form_with url: locations_path, method: :get do |form| %>
  <%= form.text_field :product_name, value: params[:product_name] %>
  <%= form.text_field :place, value: params[:place] %>
  <%= form.select :distance, [10, 100], selected: params[:distance] %>
  <%= form.submit %>
<% end %>
```

Find locations that have product you are searching for:

```ruby
# app/controllers/locations_controller.rb
  def index
    locations = Location.joins(:products).includes(:products) # initially select only locations that have products

    if params[:product_name].present?
      products = Product.where('name ILIKE ?', "%#{params[:product_name]}%")
      location_ids = products.select(:location_id).distinct
      locations = locations.where(id: location_ids)
    end

    if params[:place].present?
      locations = locations.near(params[:place], params[:distance] || 10, order: :distance)
    end
    @locations = locations
  end
```

Don't forget to add `product_name: params[:product_name]` to the JSON map path:

```ruby
<%= js_map locations_path(format: :json, place: params[:place], product_name: params[:product_name], distance: params[:distance]) %>
```

Result: find locations that offer a specific product/service:

![search-by-child.gif](/assets/images/search-by-child.gif)

That's it! Now you can build your own AIRNBN search frontend!
