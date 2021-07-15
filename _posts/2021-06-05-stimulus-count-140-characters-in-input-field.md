---
layout: post
title: "Stimulus Rails - Count characters in input field (+ add css if > 140 characters)"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stimulus
thumbnail: /assets/thumbnails/stimulus-logo.png
---

** Disclaimer: I'm still experimenting with Stimulus and this might not be the best way to do things **

Prerequisites:
* rails 6
* stimulus 2

Final solution demo:

![stimulus-count-characters-based-on-input-css.gif](/assets/images/stimulus-count-characters-based-on-input-css.gif)

HOWTO:

```ruby
<%= form_with(model: post) do |form| %>
  <%= content_tag :div, nil, data: { controller: "tweet", tweet_character_count_value: 140, tweet_over_limit_class: "text-danger" } do %>
    <%= form.text_area :content, data: { controller: "textarea-autogrow", tweet_target: "field", action: "keyup->tweet#change" } %>
    <div data-tweet-target="output"></div>
  <% end %>
<% end %>
```

tweet_controller.js
```ruby
import { Controller } from "stimulus"
export default class extends Controller {
  static targets = [ "field", "output" ]
  static classes = [ "overLimit" ]
  static values = {
    characterCount: Number,
  }

  connect() {
    this.change()
  }

  change() {
    let length = this.fieldTarget.value.length
    this.outputTarget.textContent = `${length} characters`

    if (length > this.characterCountValue) {
      this.outputTarget.classList.add(this.overLimitClass)
    } else {
      this.outputTarget.classList.remove(this.overLimitClass)
    }
  }
}
```

Disclaimer 2: This particular code is 99% based on a go rails episode
