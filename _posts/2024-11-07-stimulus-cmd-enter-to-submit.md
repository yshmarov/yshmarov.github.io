---
layout: post
title: StimulusJS Cmd Enter to submit form
author: Yaroslav Shmarov
tags: keyboard hotkeys stimulusjs stimulus
thumbnail: /assets/thumbnails/stimulus-logo.png
---

Kasper gave Jeremy the idea of `Cmd+Enter` for submitting comments in his app:

![liminal forum - submit form with keyboard](/assets/images/liminal-cmd-enter-submit-idea.jpeg)

I took this idea and implemented it on [SupeRails](https://superails.com/posts).

Now, when creating a `Comment`, you can submit the form with your keyboard by clicking `Cmd/Ctrl+Enter`.

This is a common web behaviour nowadays.

Here's how you can add `Cmd/Ctrl+Enter` to your app with StimulusJS:

### 1. Worst approach

- Without using stimulus data-action keyboard events
- With event listeners

```js
// app/javascript/controllers/form_controller.js
export default class extends Controller {
  static targets = ["input", "submit"];

  connect() {
    this.inputTarget.addEventListener("keydown", this.submitOnCmdEnter.bind(this));
  }

  disconnect() {
    this.inputTarget.removeEventListener("keydown", this.submitOnCmdEnter.bind(this));
  }

  submitOnCmdEnter(event) {
    let pressedCtrl = event.metaKey || event.ctrlKey
    if (pressedCtrl && event.key === "Enter") {
      event.preventDefault();
      this.submitTarget.click();
    }
  }
}
```

```html
<form action="/posts"
      data-controller="form">
  <textarea data-form-target="input" name="content"></textarea>
  <button data-form-target="submit">Submit</button>
</form>
```

### 2. Slightly better approach

Use data-action instead of event listener

```js
// app/javascript/controllers/form_controller.js
export default class extends Controller {
  submitOnCmdEnter(event) {
    let pressedCtrl = event.metaKey || event.ctrlKey
    if (pressedCtrl && event.key === "Enter") {
      event.preventDefault();
      this.submitTarget.click();
    }
  }
}
```

```html
<form action="/posts"
      data-controller="form">
  <textarea data-action="keydown->form#submitOnCmdEnter" name="content"></textarea>
</form>
```

### 3. Best approach

You don't even need to define `Cmd/Ctrl+Enter` in your Stimulus controller!

Just use StimulusJS [Keyboard events](https://stimulus.hotwired.dev/reference/actions#keyboardevent-filter)

```js
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  submit() {
    this.element.requestSubmit();
  }
}
```

```html
<form action="/posts"
      data-controller="form"
      data-action="keydown.ctrl+enter->form#submit keydown.meta+enter->form#submit">
  <textarea name="content"></textarea>
</form>
```

That's it! Now visit SupeRails, and try creating a comment with `Cmd/Ctrl+Enter`!
