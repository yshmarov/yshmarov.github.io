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

Result:

![mapbox-map-all-params](/assets/images/mapbox-map-all-params.png)

### HTML tooltips

Map with clickable links to locations:

![mapbox-map-clickable-link](/assets/images/mapbox-map-clickable-link.png)

Create a helper with a link:

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

Result:

![mapbox-map-multiple-locations](/assets/images/mapbox-map-multiple-locations.png)

### With search params

In this final example, we will factor in having a search form for `place` and `distance`. The maps' `zoom` will be smaller/higher based on the maximum search `distance`:

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  before_action :set_location, only: %i[ show edit update destroy ]

  # GET /locations or /locations.json
  def index
    if params[:place].present?
      @locations = Location.near(params[:place], params[:distance] || 10, order: :distance)
      # this!
      @zoom = params[:distance].eql?('10') ? 13 : 10
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

Result - smaller/bigger map zoom based on search params:

![geocoder-search-zoom](/assets/images/geocoder-search-zoom.gif)

That's it! Now you can build your own AIRNBN search frontend!
