---
layout: post
title: "StimulusJS Textarea autogrow"
author: Yaroslav Shmarov
tags: stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

**Regular** `<textarea>` **without** autogrow:

![text area without autogrow](/assets/images/without-autogrow.gif)

**Improved** `<textarea>` **with** autogrow:

![text area with autogrow](/assets/images/with-autogrow-good.gif)

How it works:

Just connect the below stimulus controller to a `<textarea>` and you're good to go!

```sh
rails g stimulus autogrow
```

```js
// app/javascript/controllers/autogrow.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autogrow"
// <%= form.text_area :content, data: {controller: "autogrow" } %>
// <textarea data-controller="autogrow" name="article[content]"></textarea>

export default class extends Controller {
  initialize() {
    this.autogrow = this.autogrow.bind(this);
  }

  connect() {
    this.element.style.overflow = 'hidden';
    this.autogrow();
    this.element.addEventListener('input', this.autogrow);
    window.addEventListener('resize', this.autogrow);
  }

  disconnect() {
    window.removeEventListener('resize', this.autogrow);
  }

  autogrow() {
    this.element.style.height = 'auto';
    this.element.style.height = `${this.element.scrollHeight}px`;
  }
}
```

Based on the fantastic [@guillaumebriday's stimulus-textarea-autogrow](https://github.com/stimulus-components/stimulus-textarea-autogrow/blob/master/src/index.ts){:target="blank"}
