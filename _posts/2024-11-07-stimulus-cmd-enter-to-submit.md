---
layout: post
title: StimulusJS Cmd Enter to submit form
author: Yaroslav Shmarov
tags: rails markdown
thumbnail: /assets/thumbnails/stimulus-logo.png
---

On [SupeRails](https://superails.com/posts), when creating a `Comment`, you can submit the form with your keyboard by clicking `Cmd/Ctrl+Enter`.

This is a common web behaviour nowadays.

Here's how you can add `Cmd/Ctrl+Enter` to your app with StimulusJS:

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

You don't even need to define `Cmd/Ctrl+Enter` in your Stimulus controller!

Just use StimulusJS [Keyboard events](https://stimulus.hotwired.dev/reference/actions#keyboardevent-filter)

```html
<form action="/posts"
      data-controller="form"
      data-action="keydown.ctrl+enter->form#submit keydown.meta+enter->form#submit">
  <textarea name="content"></textarea>
</form>
```

That's it! Now visit SupeRails, and try creating a comment with `Cmd/Ctrl+Enter`!
