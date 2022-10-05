---
layout: post
title: "The limits of Turbo. Custom Turbo Steam Actions"
author: Yaroslav Shmarov
tags: ruby-on-rails-7 hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

### 1. responce should refresh a turbo_frame

- ? Why not `replace`/`update` the `turbo_frame` content with a `turbo_stream`?
- > Not to get into context of locals for that frame in your current controller action.

```ruby
# app/helpers/turbo_stream_helper.rb
module TurboStreamHelper
  # refresh a frame
  def turbo_stream_navigate(url, frame: "_top", action: nil)
    link = tag.a( # construct a link with a GET request that will be placed ? WHERE ?
      nil, # no label needed
      class: "hidden", # just in case, so that it does not appear in the HTML
      href: url, # the URL on which to look for the turbo_frame ?
      data: {
        controller: "click-on-connect", click_on_connect_open_value: true, # click the link
        turbo_frame: frame, # will target a frame or top?
        turbo_action: action, # ?
        turbo_cache: false # ?
      }
    )

    if frame == "_top"
      turbo_stream.append_all("body") { link } # does not rely on the presence of an element with a certain ID
    else
      turbo_stream.append(frame) { link }
    end
  end
end
```

```js
// app/javascript/controllers/click_on_connect_controller.js
import { Controller } from "@hotwired/stimulus"

// to be applied on a link or button
// conditionally clicks on the element
// example - open a turbo modal on page redirect

// controller: "click-on-connect", click_on_connect_open_value: true
export default class extends Controller {
  static values = { open: Boolean }
  connect() {
    if (this.openValue) {
      this.element.click()
    }
  }
}
```

```ruby
# tasks_controller.rb
  def destroy
    reload_inventory_subsection
  end

  private

  def reload_inventory_subsection
    render turbo_stream: helpers.turbo_stream_navigate(
      request.referer,
      frame: "inventory_subsection",
      action: :replace
    )
  end
```

```ruby
# viewstasks/like.turbo_stream.erb
<%= turbo_stream_navigate request.referer, frame: "inventory_subsection", action: :replace %>
<%= turbo_stream_navigate request.referer, frame: "inventory_subsection", action: :nil %>
```

### 2. navigate to a page
https://dev.to/rolandstuder/custom-turbo-stream-actions-2gh1