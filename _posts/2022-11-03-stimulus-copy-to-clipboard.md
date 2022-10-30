---
layout: post
title: "StimulusJS advanced copy to clipboard"
author: Yaroslav Shmarov
tags: stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

In this example we will copy to clipboard with some added visual effects 💅

When you click `copy`:
* **replace** the `copy` text with `copied`
* **focus** on the content that has been copied

2 seconds later:
* **replace** the `copied` text with `copy`
* **UNfocus** on the content that has been copied

Final result:

![stimulus-copy-clipboard](/assets/images/stimulus-copy-clipboard.gif)

Stimulus controller:
* `source` - content that will be copied
* `trigger` - button that gets clicked/replaced

```js
// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "trigger"]

  copy(event) {
    event.preventDefault()
    navigator.clipboard.writeText(this.sourceTarget.value)
 
    this.sourceTarget.focus()
    var triggerElement = this.triggerTarget
    var initialHTML = triggerElement.innerHTML
    triggerElement.innerHTML = "<span style='color:grey;'>Copied</span>"
    setTimeout(() => {
      triggerElement.innerHTML = initialHTML
      // unfocus
      this.sourceTarget.blur()
    }, 2000)
  }
}
```

HTML:

```html
<div data-controller="clipboard">
  <input data-clipboard-target="source"
         class="font-extralight text-xs h-6 rounded-md"
         type="text" value="<%= insta_user_post_url(post.insta_user, post) %>" readonly>
  <button data-clipboard-target="trigger" data-action="clipboard#copy">Copy</button>
</div>
```

That's it!

Share link:
https://developer.mozilla.org/en-US/docs/Web/API/Navigator/share

https://github.com/Deanout/share_button
