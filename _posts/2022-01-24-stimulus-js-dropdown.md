---
layout: post
title: "Stimulus JS: A Basic Dropdown controller"
author: Yaroslav Shmarov
tags: stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

Today I had a challenge to create a button to open/hide content on the frontend side:

![stimulus-dropdown-controller](/assets/images/stimulus-dropdown-controller.gif)

I've done something very similar before in
[Stimulus Read More - MY WAY!!!]({% post_url 2021-07-30-stimulus-read-more %}),
however this time it's a bit different:

* No content should be visible in the dropdown target when it is "collapsed"
* Optionally have the Dropdown open/closed **by default**
* Display different HTML for the show/hide buttons (same as read-more controller)

And this is finally a good example to utilize **Stimulus Values**!

Here's the stimulus controller:

```js
import { Controller } from "@hotwired/stimulus"
 // Minimalistic dropdown toggle controller.
 // Click to open/close dropdown.
 // When clicked, dropdown icon can be changed.
 // Dropdown can be open by default, if you set data-mini-dropdown-open-value="true" (closed by default if not set)

 export default class extends Controller {
   static targets = ["dropdownContent", "openButton", "closeButton"]
   static values = { open: Boolean }

   connect() {
     if (this.openValue) {
       this.openDropdown()
     } else {
       this.closeDropdown()
     }
   }

   openDropdown() {
     this.openButtonTarget.hidden = true
     this.closeButtonTarget.hidden = false
     this.dropdownContentTarget.hidden = false
   }

   closeDropdown() {
     this.openButtonTarget.hidden = false
     this.closeButtonTarget.hidden = true
     this.dropdownContentTarget.hidden = true
   }
 }
 ```

And here is the HTML:

```html
<div data-controller="mini-dropdown" data-mini-dropdown-open-value="false">
  <button role="button" tabindex=0 data-mini-dropdown-target="openButton" data-action="mini-dropdown#openDropdown">
    Click to Open
  </button>
  <button role="button" tabindex=0 data-mini-dropdown-target="closeButton" data-action="mini-dropdown#closeDropdown" >
    Click to Close
  </button>
  <div data-mini-dropdown-target="dropdownContent">
    Dropdown content
  </div>
</div>
```

You can make the component open/closed by default by adding some rails `true/false` logic to `data-mini-dropdown-open-value`, like `data-mini-dropdown-open-value="<%= @post.published? %>"`

Result:

![stimulus-dropdown-controller](/assets/images/stimulus-dropdown-controller.gif)

Simple, huh? Add some nice CSS on top - and it can look very sexy! Here's an example of a double-dropdown in a real app:

![stimulus-dropdown-controller-demo](/assets/images/stimulus-dropdown-controller-demo.gif)

That's it!
