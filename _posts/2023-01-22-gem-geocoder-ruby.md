---
layout: post
title: "gem Geocoder - calculate coordinates, distances, search nearby"
author: Yaroslav Shmarov
tags: ruby rails geocoder
thumbnail: /assets/thumbnails/map-marker.png
---

[Geocoder gem](https://github.com/alexreisner/geocoder){:target="blank"} allows you to preform different operations with **coordinates**.

Useful usage examples:
* find `latitude` and `longitude` coordinates by `address`, 
* `address` by `lat-lon` coordinates, 
* find all Locations within a **square** (`within_bounding_box`)
* find the **distance** between two Locations (`distance_from`)
* find all Locations around X **coordinates** (`near`)
* find all Locations around X **location** (`nearbys`)

Afterwards, when you have the coordinates of a location, you can use a **separate** Maps API to display them on a map.

### Basic geocoder usage

Geocoder gem does a search via a Places API, and returns coordinates. The more detailed address you search for, the more precise the coordinates you will receive.

```ruby
bundle add geocoder

# search
ua = Geocoder.search('Kyiv')
ua.first.coordinates
# => [50.4500336, 30.5241361] # latitude and longitude
ua.first.country
# => 'Ukraine'

fr = Geocoder.search('Notre dame cathedral paris')
fr.first.city
# => 'Paris'

# geographic_center
Geocoder::Calculations.geographic_center([ua.first.coordinates, fr.first.coordinates])
# => [50.51223060957045, 16.201193185230583]
```

### Debug current HTTP request

You can get the current web requests country/ip/etc.

You can use it, for example, to [geoblock countries like Ruzzia]({% post_url 2022-02-25-block-russian-ips %}){:target="blank"}

```ruby
# controller or view
request.location
request.location
request.location.try(:country)
# request.ip
```

### Geocode a Rails model

Storing the address as a single string looks like a simple straightforward solution, however storing each address detail separately gives you more power.

A usual address on Google Maps has the sequence `street, city, state, country, zip`.

Scaffold your location model:

```ruby
rails g scaffold Location latitude:float:index longitude:float:index street city state country zip
rails g scaffold Location latitude:float:index longitude:float:index address
rails db:migrate
```

Geocoder will automatically perform a search and find the `latitude` and `longitude` of your location.

To save compute power and API thresholds, it makes sence to geocode only if the address has changed.

Basic (one `address` field):

```ruby
# app/models/location.rb
  geocoded_by :address   
  after_validation :geocode, if: :address_changed?
  # after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed? }
```

Advanced (multiple `address` fields):

```ruby
# app/models/location.rb
  geocoded_by :address   
  after_validation :geocode, if: :address_changed? 

  def address 
    [street, city, state, country, zip].compact.join(', ')
  end

  private

  def address_changed?
    country_changed? ||
      state_changed? 
      city_changed? ||
      street_changed? ||
      zip_changed? ||
  end 
```

**DEMO DATA**: seeds with a few real hotels in France

```ruby
# db/seeds.rb
name = "Hôtel Martinez - The Unbound Collection by Hyatt"
address = "73 Bd de la Croisette, 06400 Cannes"
Location.create(name:, address:)

name = "Exclusive Hotel Belle Plage"
address = "2 Rue Brougham, 06400 Cannes"
Location.create(name:, address:)

name = "Best Western Premier Le Patio des Artistes - Cannes"
address = "6 Rue de Bône, 06400 Cannes"
Location.create(name:, address:)

name = "Le Negresco"
address = "37 Prom. des Anglais, 06000 Nice"
Location.create(name:, address:)

name = "Caesars Palace"
address = "3570 S Las Vegas Blvd, Las Vegas, NV 89109, United States"
Location.create(name:, address:)
```

Now you can find call geocoder methods on the model.

```ruby
# geocode a single record:
address = Address.first
address.geocode
address.save

# geocode all:
Location.all.each { |location| location.geocode && location.save }

Location.geocoded
# => return objects with coordinates
Location.not_geocoded
# => return objects without coordinates

Location.first.to_coordinates
# => [51.51436195, 31.31593525714063]

Location.first.nearbys(20)
Location.first.nearbys(20, units: :km)
# => array of locations within 20 km of coordinates, excluding selected location
# ! useful to show "similar" or "nearby" feature

Location.near(Location.first, 20, units: :km, order: :distance)
Location.near('Omaha, NE, US', 20)
# => all locations within 20 km of coordinates
# ! useful for "find all next to...." feature

Location.first.distance_from(Location.second)
Location.first.distance_to(Location.second) # same as above
Location.first.distance_form([40.714,-100.234])
# => 1.8493403104012456

# all locations within square
sw_corner = [40.71, 100.23] 
ne_corner = [36.12, 88.65]
Location.within_bounding_box(sw_corner, ne_corner)
```

### Search locations near

Having a search for for `place` and `distance`, you can find relevant Locations. This can be a vital feature when building a website like AirBnB or Booking.com.

Example query in human words: *Find all locations within 10km distance from Chernihiv, Ukraine*

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  def index
    if params[:place].present?
      @locations = Location.near(params[:place], params[:distance] || 10, order: :distance)
    else
      @locations = Location.all
    end
  end
end
```

```ruby
# a view
<%= form_with url: locations_path, method: :get do |form| %>
  <%= form.label :place, "City, Country" %>
  <%= form.text_field :place, value: params[:place] %>

  <%= label :distance, "Distance, km" %>
  <%= text_field_tag :distance, [10, 20, 30], params[:distance] %>

  <%= form.submit "Search" %>
<% end %>
```

### Display coordinates on static map

To display a market on a static image map, you would need to connect a places API.

There are a few options for using Places API:
* [🔥🔥 **Mapbox maps**](https://docs.mapbox.com/playground/static/){:target="blank"}
* [🔥 **google maps**](https://developers.google.com/maps/documentation/maps-static){:target="blank"}
* [❓ **Bing maps**](https://learn.microsoft.com/en-us/bingmaps/rest-services/imagery/get-a-static-map#get-a-road-map-with-building-footprints){:target="blank"}
* [❓ **HERE maps**](https://www.here.com/){:target="blank"}

From the above, I've tried only Mapbox. As long as you receive a Mapbox API key, you can display the map with an `image_tag`:

```ruby
<%= image_tag "https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/pin-s+ff2700(#{location.longitude},#{location.latitude})/#{location.longitude},#{location.latitude},13,0/300x200?access_token=#{Rails.application.credentials.dig(:mapbox_key)}" %>
```

There's much more that we can do with coordinates. In the future I hope to explore:
* gem Mapkick for displaying multiple Locations on a responsive map
* different Geocoding API adapters (like Amazon Location API)
* get browser location with Javascript

That's it for now.