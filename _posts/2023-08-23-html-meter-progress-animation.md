---
layout: post
title: "Progress animation with HTML meter element and javascript"
author: Yaroslav Shmarov
tags: rails stimulusjs html
thumbnail: /assets/thumbnails/stimulus-logo.png
---

Example of an HTML `<meter>` element that is gradually filled and disappears on 100%.

In a web app this could be a great progress indicator, or animation on a disappearing flash message.

![html animated meter element](/assets/images/html-dynamic-meter.gif)

```html
0,5 seconds (500ms)
<meter data-controller="meter" data-meter-duration-value="500"></meter>

2 seconds (2000ms)
<meter data-controller="meter" data-meter-duration-value="2000"></meter>

5 seconds (5000ms)
<meter data-controller="meter"></meter>
```

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    duration: { type: Number, default: 5000 }
  }

  connect() {
    this.element.value = 0
    this.element.min = 0
    this.element.max = 100

    this.startProgress();
  }

  startProgress() {
    // 50ms interval for 1% over 5 seconds
    let interval = this.durationValue / 100
    this.progressInterval = setInterval(() => {
      this.incrementProgress();
    }, interval);
  }

  incrementProgress() {
    const currentProgress = this.element.value;
    if (currentProgress < 100) {
      this.element.value = currentProgress + 1;
    } else {
      clearInterval(this.progressInterval);
      this.element.classList.add('hidden')
    }
  }
}
```

That's it! 🤠
