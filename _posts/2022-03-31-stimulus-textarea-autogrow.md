---
layout: post
title: "StimulusJS Textarea autogrow"
author: Yaroslav Shmarov
tags: stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

**Standard** `<textarea>` does not autogrow while you add new rows:

![text area without autogrow](/assets/images/without-autogrow.gif)

**Improved** `<textarea>` **with** autogrow:

![text area with autogrow](/assets/images/with-autogrow-good.gif)

### 14.06.2023 updated version:

Just connect the below stimulus controller to a `<textarea>` and you're good to go!

```sh
rails g stimulus autogrow
```

StimulusJS controller inspired by [MDN HTMLTextAreaElement example](https://developer.mozilla.org/en-US/docs/Web/API/HTMLTextAreaElement#autogrowing_textarea_example):

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.overflow = 'hidden';
    this.grow();
  }

  grow() {
    const textarea = this.this.element;
    if (textarea.scrollHeight > textarea.clientHeight) {
      textarea.style.height = `${textarea.scrollHeight}px`;
    }
  }

  // bad approach:
  // grow() {
  //   this.element.style.height = 'auto';
  //   this.element.style.height = `${this.element.scrollHeight}px`;
  // }
}
```

Usage with `html.erb`:

```ruby
<%= form.text_area :content,
                    # rows: 5,
                    data: { controller: 'autogrow',
                            action: "input->autogrow#grow" } %>
```

### 31.03.2022 version:

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

This old version is based on the fantastic [@guillaumebriday's stimulus-textarea-autogrow](https://github.com/stimulus-components/stimulus-textarea-autogrow/blob/master/src/index.ts){:target="blank"}
