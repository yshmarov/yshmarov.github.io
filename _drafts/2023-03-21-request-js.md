---
layout: post
title: "Why do you need to use RequestJS"
author: Yaroslav Shmarov
tags: stimulusjs requestjs request-js
thumbnail: /assets/thumbnails/trello.png
---

There are a lot of on-page Javascript events that happen in your app. It is likely that you would want to make and HTTP request based on some of them. 

Basic examples:
- track clicks on a page and write to Redis or Postgresql (`POST` request)
- autocomplete search with tom-select or (`GET` request)
- create a new Tag (`POST` request)

With jQuery, we used to make HTTP requests more-less like this:

```js
$.ajax({
  type     : 'POST',
  url      : '/tags',
  dataType : 'json',
  data     : "{ article: { tags: {name: 'Ruby'} }"
})
```

Now jQuery is a legacy tenchnology, and adding it to a Rails app is mouvais-ton.

Instead, use [rails/request.js](https://github.com/rails/requestjs-rails).

RequestJS makes it easy to make an HTTP request from a StimulusJS controller. Most commonly, you would send an internal request to a Rails controller action without having to `skip_before_action :verify_authenticity_token`.

### Install requestjs-rails:

```shell
bundle add requestjs-rails
./bin/rails requestjs:install
```

### GET request

### POST request

```html
<!-- analytics -->
<button data-controller='click-counter'>
  save click to postgres
</button>
```

```js
```

### PATCH request

```js
// app/javascript/controllers/ui_state_controller.js
 
import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";
 
export default class extends Controller {
  static values = {
    departmentId: Number,
  };
 
  async toggle() {
    const body = new FormData();
    body.append("open", this.element.open);
    body.append("department_id", this.departmentIdValue);
 
    await patch("/ui_state/update", {
      body,
    });
  }
}
```

```html
<details
  data-controller="ui-state"
  data-action="toggle->ui-state#toggle"
  data-ui-state-department-id-value="<%= dep.id %>"
>
```

### Step 2: Store coordinates in Rails session.

```diff
<div data-controller="geolocation"
+     data-geolocation-url-value="<%= geolocate_path %>">
  <button data-action="click->geolocation#search">Get location</button>
</div>
```

```js
import { Controller } from "@hotwired/stimulus"
import { put } from "@rails/request.js";
// import { patch } from '@rails/request.js'

// Connects to data-controller="geolocation"
export default class extends Controller {
  static targets = [ "link" ]
  static values = { url: String };

  success(position) {
    put(this.urlValue, {
      body: JSON.stringify({latitude: position.coords.latitude,
                            longitude: position.coords.longitude })
    });
    // get(this.urlValue, {
    //   query: { latitude: position.coords.latitude, longitude: position.coords.longitude }
    // })
  }
}
```