---
layout: post
title: "StimulusJS - Display or hide HMTL based on field input"
author: Yaroslav Shmarov
tags: stimulus
thumbnail: /assets/thumbnails/stimulus-logo.png
youtube_id: Ku_SVWl_u64
updated: 2024-08-30
---

Task: unhide some HTML (or a form field) based on your selection.

This solution is flexible, as you don't hard-code any values in the stimulus controller.

Prerequisites:
* rails 6+
* stimulus 2+

### Option 1 - without CSS

Final solution:

![show-html-if-selected-value-matches.gif](/assets/images/show-html-if-selected-value-matches.gif)

```js
// /app/javascript/controllers/showhide_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="showhide"
export default class extends Controller {
  static targets = ["input", "output"]
  static values = { showIf: String }
  connect() {
    this.toggle()
  }

  toggle() {
    if (this.inputTarget.value != this.showIfValue) {
      this.outputTarget.hidden = true
    } else if (this.inputTarget.value = this.showIfValue) {
      this.outputTarget.hidden = false
    }
  }
}
```

HMTL example:

```html
<div data-controller="showhide" data-showhide-show-if-value="human">
  <select data-showhide-target="input" data-action="change->showhide#toggle">
    <option selected="selected" value=""></option>
    <option value="human">human</option>
    <option value="animal">animal</option>
  </select>
  <div data-showhide-target="output" hidden="">
    an output if human
  </div>
</div>
```

Rails form example:

```ruby
# /app/views/posts/_form.html.erb
<%= form_with(model: post) do |form| %>
  <div data-controller="showhide" data-showhide-show-if-value="human">
    <%= form.select "abc", ["", "human", "animal"], {allow_blank: true}, {data: {showhide_target: "input", action: "change->showhide#toggle"}} %>
    <div data-showhide-target="output">
      an output if human
    </div>
  </div>
<% end %>
```

### Option 2 - leveraging Stimulus `classes`

Final solution:

![stimulus-unhide-based-on-input.gif](/assets/images/stimulus-unhide-based-on-input.gif)


```css
/* app/assets/stylesheets/application.css */
.hidden {
  display: none
}
```

```js
// /app/javascript/controllers/showhide_controller.js
import { Controller } from "stimulus"
export default class extends Controller {
  static targets = [ "field", "output" ]
  static classes = [ "hide" ]
  static values = {
    showIf: String,
  }

  connect() {
    this.toggle()
  }

  toggle() {
    if (this.fieldTarget.value != this.showIfValue) {
      this.outputTarget.classList.add(this.hideClass)
    } else {
      this.outputTarget.classList.remove(this.hideClass)
    }
  }
}
```

Rails form example:

```ruby
# /app/views/posts/_form.html.erb
<%= form_with(model: post) do |form| %>
  <%= content_tag :div, nil, data: { controller: "showhide", showhide_show_if_value: "lorem", showhide_hide_class: "hidden" } do %>
    <%= form.select :content, [nil, "lorem", "other"], {}, {data: { showhide_target: "field", action: "change->showhide#toggle" }} %>
    <div data-showhide-target="output">
      you can see this text if selected value = lorem
    </div>
  <% end %>
<% end %>
```

P.S. Don't forget that you are free to have multiple same stimulus controllers on a page ;)

## September 2024 update

This is a battle-tested, perfected approach:

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="showifvalue"
// show div if value of input is equal to data-showif-value
// hidden divs have all inputs and selects disabled
export default class extends Controller {
  static targets = ['input', 'output']

  connect() {
    this.toggle()
  }

  toggle() {
    var value = this.inputTarget.value

    this.outputTargets.forEach(outputTarget => {
      var selectedValue = outputTarget.dataset.showifValue
      if (selectedValue === value) {
        this.showOutputTarget(outputTarget)
      } else {
        this.hideOutputTarget(outputTarget)
      }
    })
  }

  hideOutputTarget(outputTarget) {
    outputTarget.hidden = true
    outputTarget.disabled = true
    outputTarget.querySelectorAll('select').forEach(select => {
      select.setAttribute('disabled', true)
    })
    outputTarget.querySelectorAll('input').forEach(input => {
      input.setAttribute('disabled', true)
    })
  }

  showOutputTarget(outputTarget) {
    outputTarget.hidden = false
    outputTarget.disabled = false
    outputTarget.querySelectorAll('select').forEach(select => {
      select.removeAttribute('disabled')
    })
    outputTarget.querySelectorAll('input').forEach(input => {
      input.removeAttribute('disabled')
    })
  }

  inputTargetConnected() {
    this.toggle()
  }

  inputTargetDisconnected() {
    this.toggle()
  }

  outputTargetConnected() {
    this.toggle()
  }

  outputTargetDisconnected() {
    this.toggle()
  }
}
```

HTML

```ruby
<%= form_with(model: company, data: { controller: "showifvalue" }) do |form| %>
  <div>
    <%= form.label :country %>
    <%= form.select :country, ["FR", "GB"], { include_blank: true }, data: { showifvalue_target: "input", action: "change->showifvalue#toggle" } %>
  </div>

  <div data-showifvalue-target="output" data-showif-value="FR">
    <%= form.label :search_fr %>
    <%= form.text_field :search_fr %>
  </div>

  <div data-showifvalue-target="output" data-showif-value="GB">
    <%= form.label :search_gb %>
    <%= form.text_field :search_gb %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

Try it out!
