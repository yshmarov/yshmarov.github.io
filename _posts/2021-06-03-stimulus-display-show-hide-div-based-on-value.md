---
layout: post
title: "Stimulus Rails - Display or hide div based on field input"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stimulus
thumbnail: /assets/thumbnails/stimulus-logo.png
---

** Disclaimer: I'm still experimenting with Stimulus and this might not be the best way to do things **

Prerequisites:
* rails 6
* stimulus 2
* bootstrap 5

Final solution demo:

![stimulus-unhide-based-on-input.gif](/assets/images/stimulus-unhide-based-on-input.gif)

HOWTO:

/app/javascript/controllers/showhide_controller.js

```
import { Controller } from "stimulus"
export default class extends Controller {
  static targets = [ "field", "output" ]
  static classes = [ "hide" ]
  static values = {
    showIf: String,
  }

  connect() {
    this.change()
  }

  change() {
    if (this.fieldTarget.value != this.showIfValue) {
      this.outputTarget.classList.add(this.hideClass)
    } else {
      this.outputTarget.classList.remove(this.hideClass)
    }
  }
}
```

/app/views/posts/_form.html.erb

```
<%= form_with(model: post) do |form| %>
  <%= content_tag :div, nil, data: { controller: "showhide", showhide_show_if_value: "lorem", showhide_hide_class: "d-none" } do %>
    <%= form.select :content, [nil, "lorem", "150"], {}, {data: { showhide_target: "field", action: "change->showhide#change" }} %>
    <div data-showhide-target="output">
      you can see this text if selected value = lorem
    </div>
  <% end %>
<% end %>
```

`d-none` is a bootstrap5 class for hiding
