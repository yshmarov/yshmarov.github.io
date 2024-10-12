---
layout: post
title: "StimulusJS Keyboard Hotkeys (Keyboard navigation)"
author: Yaroslav Shmarov
tags: tabs stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
youtube_id: OlMtq6yRmI4
---

Some apps let you click keyboard buttons or combinations to quickly navigate around.

Example 1:

![hotkeys-links](/assets/images/hotkeys-links.png)

Example 2:

![hotkeys-search](/assets/images/hotkeys-search.png)

**Goal**: If a user presses a hotkey combination on a keyboard, trigger a click on a link, button or element.

In our example a user will always have to click `⌘ Command` + `yourKey` (Mac), or `Ctrl` + `yourKey` (Linux/Windows).

#### Option 1: With event listeners

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="hotkeys"
export default class extends Controller {
  static targets = ["button"]

  connect() {
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    // meta for Mac, ctrl for Linux/Windows
    let pressedCtrl = event.metaKey || event.ctrlKey
    let pressedKey = event.key
    if (pressedCtrl) {
      // find a buttonTarget that has hotkey set to the pressed key
      let buttonTarget = this.buttonTargets.find((el) => el.dataset.hotkey == pressedKey)
      if (buttonTarget) {
        event.preventDefault()
        buttonTarget.focus()
        buttonTarget.click()
      }
    }
  }
}
```

HTML usage example:

```html
<body data-controller="hotkeys">
  <a href="#" data-hotkeys-target="button" data-hotkey="e">Edit</a>
  <button data-hotkeys-target="button" data-hotkey="s">Save</button>
  <button data-hotkeys-target="button" data-hotkey="d">Delete</button>
</body>
```

#### Option 2 (better): with Stimulus actions

Instead of EventListeners, we can use [Stimulus KeyboardEvent Filter](https://stimulus.hotwired.dev/reference/actions#keyboardevent-filter)

```diff
-<body data-controller="hotkeys">
+<body data-controller="hotkeys" data-action="keydown->hotkeys#handleKeydown">
  <a href="#" data-hotkeys-target="button" data-hotkey="e">Edit</a>
  <button data-hotkeys-target="button" data-hotkey="s">Save</button>
  <button data-hotkeys-target="button" data-hotkey="d">Delete</button>
</body>
```

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button" ]

  handleKeydown(event) {
    // Check if Cmd (Mac) or Ctrl (Windows/Linux) is pressed simultaneously with the key
    let pressedCtrl = event.metaKey || event.ctrlKey
    let pressedKey = event.key.toLowerCase()
    
    if (pressedCtrl) {
      // find a button with data-hotkey attribute that matches the pressed key
      let buttonTarget = this.buttonTargets.find((el) => el.dataset.hotkey == pressedKey)
      if (buttonTarget) {
        event.preventDefault();
        buttonTarget.focus()
        buttonTarget.click()
      }
    }
  }
}
```

Important considerations:

* Most `Ctrl+yourKey` combination are reserved by the browser. Different browsers can have different reserved combinations. A few characters that seem to work across browsers are `k`, `u`, `b`, `k`.
* This brings value only to users with keyboards (not mobile devices)
* [Using accesskeys can have accessibility issues](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/accesskey)

That's it! 🤠
