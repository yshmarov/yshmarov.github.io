---
layout: post
title: "StimulusJS Dropdown"
author: Yaroslav Shmarov
tags: stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

Previously I've created a [Stimulus ReadMore]({% post_url 2021-07-30-stimulus-read-more %}){:target="blank"} controller.

**This** controller can be considered a much improved version of it:

![stimulus-dropdown.gif](/assets/images/stimulus-dropdown.gif)

Basically, a StimulusJS controller that can handle:
* open content on **hover** (like a tooltop)
* open content on **click**
* different HTML for `opened` and `closed` states
* highlight `opened` state
* conditionally `opened` or `closed` dropdown by default

I think this is a perfect example of leveraging Stimulus targets, values and classes all together.

HOWTO:

```sh
rails g stimulus dropdown
```

```js
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdownContent", "openButton", "closeButton", "activated"]
  static values = { open: Boolean }
  static classes = [ "opened" ]

  connect() {
    if (this.openValue) {
      this.openDropdown()      
    } else {
      this.closeDropdown()
    }
  }
  
  toggleDropdown() {
    if (this.dropdownContentTarget.hidden == true) {
      this.openDropdown()
    } else {
      this.closeDropdown()
    }
  }

  openDropdown() {
    try { this.activatedTarget.classList.add(this.openedClass) } catch {}
    try {
      this.openButtonTarget.hidden = true
      this.closeButtonTarget.hidden = false 
      this.closeButtonTarget.classList.add(this.openedClass)
      // this.activatedTarget.classList.add("bg-slate-300")
    } catch {}

    this.dropdownContentTarget.hidden = false
  }
  
  closeDropdown() {
    try { this.activatedTarget.classList.remove(this.openedClass) } catch {}
    try {
      this.openButtonTarget.hidden = false
      this.closeButtonTarget.hidden = true
      // this.dropdownContentTarget.classList.remove("bg-amber-300")
    } catch {}

    this.dropdownContentTarget.hidden = true
  }
}
```

* Option 1. open on hover:

```ruby
<div data-controller="dropdown" data-dropdown-open-value="false" data-dropdown-opened-class="bg-slate-300">
  <button data-dropdown-target="activated" data-action="mouseenter->dropdown#toggleDropdown mouseleave->dropdown#toggleDropdown">
    hover me
  </button>

  <div data-dropdown-target="dropdownContent" class="bg-red-500 fixed p-4 rounded-md">
    <h1>this could be a tooltip!</h1>
  </div>
</div>
```

* Option 2. open on click:

```ruby
<div data-controller="dropdown" data-dropdown-open-value="false" data-dropdown-opened-class="bg-slate-300">
  <button data-dropdown-target="activated" data-action="click->dropdown#toggleDropdown">
    click to toggle
  </button>

  <div data-dropdown-target="dropdownContent" class="bg-red-500 fixed p-4 rounded-md">
    <h1>HIDDEN_CONTENT</h1>
    regular html
  </div>
</div>
```

* Option 3. Different HTML for `opened` and `closed` states:

```ruby
<div data-controller="dropdown" data-dropdown-open-value="false" data-dropdown-opened-class="bg-slate-300">
  <div role="button" data-dropdown-target="openButton" data-action="click->dropdown#openDropdown">open ⬇️</div>
  <span role="button" data-dropdown-target="closeButton" data-action="click->dropdown#closeDropdown">close ⬆️</span >

  <div data-dropdown-target="dropdownContent" class="bg-red-500 fixed p-4 rounded-md">
    <h1>HIDDEN_CONTENT</h1>
  </div>
</div>
```

****

Surely, the same can be achieved without using a CSS framework.

* [hotwire modals](https://www.bearer.com/blog/how-to-build-modals-with-hotwire-turbo-frames-stimulusjs)
* [absolute vs fixed position](https://css-tricks.com/absolute-relative-fixed-positioining-how-do-they-differ/#absolute)
* Quick CSS tip: `position: fixed;` stays on the same place when page scrolls, whereas `position: absolute;` - scrolls down with page. `z-index: 2`; will place on top of the page content.
