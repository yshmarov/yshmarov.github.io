---
layout: post
title: "How to use the Browser Geolocation API with Rails"
author: Yaroslav Shmarov
tags: ruby rails geolocation geocoder
thumbnail: /assets/thumbnails/map-marker.png
youtube_id: cAEzzpvm43Y
---

Task: get users **coordinates** from browser, redirect to page with coordinates in params:

![geolocation-api-search.gif](/assets/images/geolocation-api-search.gif)

To request users' location, we will use [Web/API/Geolocation/getCurrentPosition](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition){:target="blank"} with StimulusJS.

Create stimulus controller:

```ruby
rails g stimulus geolocation
```

```js
// app/javascript/controllers/geolocation_controller.js
import { Controller } from "@hotwired/stimulus"

const options = {
  enableHighAccuracy: true,
  maximumAge: 0
};

// Connects to data-controller="geolocation"
export default class extends Controller {
  static values = { url: String }

  search() {
    navigator.geolocation.getCurrentPosition(this.success.bind(this), this.error, options);
  }
  
  success(pos) {
    const crd = pos.coords;
    // redirect with coordinates in params
    location.assign(`/locations/?place=${crd.latitude},${crd.longitude}`)
  }

  error(err) {
    console.warn(`ERROR(${err.code}): ${err.message}`);
  }
}
```

Finally, a button to get location:

```html
<div data-controller="geolocation">
  <button data-action="geolocation#search">search near me</button>
</div>
```

💡 Interestingly, if you use `this.success` instead of `this.success.bind(this)`, stimulus targets will not work within the success function.

### Get address from coordinates

Get **address** based on **coordinates** using **geocoder**, and search `near` the address:


```diff
# app/javascript/controllers/geolocation_controller.js
-    location.assign(`/locations/?place=${crd.latitude},${crd.longitude}`)
+    location.assign(`/locations/?coordinates=${crd.latitude},${crd.longitude}`)
```

```diff
# app/controllers/locations_controller.rb
  def index
+    if params[:coordinates].present?
+      place = Geocoder.search(params[:coordinates])
+      params[:place] = place.first.address
+    end

    if params[:place].present?
      @locations = Location.near(params[:place], params[:distance] || 10, order: :distance)
    else
      @locations = Location.all
    end
  end
```

That's it! Now you can get Geolocation with Javascript and use it within a Rails app!
