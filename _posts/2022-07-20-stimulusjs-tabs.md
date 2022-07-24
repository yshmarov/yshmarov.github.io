---
layout: post
title: "StimulusJS Tabs"
author: Yaroslav Shmarov
tags: tabs stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

Previously I did a post covering
[lazy-loading tabs with Turbo Frames]({% post_url 2021-10-26-tabbed-content-with-hotwire-turbo-frames %}){:target="blank"}

That's a great appraoch, but not always will you want a separate route-controller-view for each tab.

Sometimes JS tabs are just enough.

Now, I'm not a JS god, but I present you with my minimalistic approach to handling **tabs** with StimulusJS.

How it works:
* click a button -> unhide the related tab
* click another button -> hide previous tab, open related tab
* click current active button -> hide this tab (all) tabs
* optionally, a select tab can be open by default

![stimulus-js-tabs](/assets/images/stimulus-js-tabs.gif)

HOWTO:

1. generate a blank stimulus controller:

```shell
rails g stimulus tabs
```

2. the stimulus controller:

```js
// app/javascript/controllers/tabs_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["btn", "tab"]
  static values = { defaultTab: String }

  connect() {
    this.tabTargets.map(x => x.hidden = true) // hide all tabs by default
    // OPEN DEFAULT TAB
    try {
      let selectedBtn = this.btnTargets.find(element => element.id === this.defaultTabValue)
      let selectedTab = this.tabTargets.find(element => element.id === this.defaultTabValue)
      selectedTab.hidden = false
      selectedBtn.classList.add("active")
    } catch { }
  }

  select(event) {
    // find tab with same id as clicked btn
    let selectedTab = this.tabTargets.find(element => element.id === event.currentTarget.id)
    if (selectedTab.hidden) {
      // CLOSE CURRENT TAB
      this.tabTargets.map(x => x.hidden = true) // hide all tabs
      this.btnTargets.map(x => x.classList.remove("active")) // deactive all btns
      selectedTab.hidden = false // show current tab
      event.currentTarget.classList.add("active") // active current btn
    } else {
      // OPEN CURRENT TAB
      this.tabTargets.map(x => x.hidden = true) // hide all tabs
      this.btnTargets.map(x => x.classList.remove("active")) // deactive all btns
      selectedTab.hidden = true // hide current tab
      event.currentTarget.classList.remove("active") // deactive current btn
    }
  }
}
```

3. add a CSS `.active` class:

```css
/* app/assets/stylesheets/application.css */
.active {
  color: blue;
}
```

4. HTML required for the stimulus controller to work:

* `data-tabs-default-tab-value="two"` - optional default open tab
* each `button` must have a `target="btn"` and `action="click->tabs#select"`
* each `tab` must have a `target="tab"`
* each `button`-`tab` combination must have the same `id`

```html
<div data-controller="tabs" data-tabs-default-tab-value="two">
  <button id="one" data-tabs-target="btn" data-action="click->tabs#select">UK</button>
  <button id="two" data-tabs-target="btn" data-action="click->tabs#select">France</button>
  <button id="abc" data-tabs-target="btn" data-action="click->tabs#select">Ukraine</button>
  <div data-tabs-target="tab" id="one">
    London, Glasgow
  </div>
  <div data-tabs-target="tab" id="two">
    Paris, Lyon
  </div>
  <div data-tabs-target="tab" id="abc">
    Kyiv, Lviv
  </div>
</div>
```

If you know a better solution or if you can improve this controller please comment below.

That's it!
