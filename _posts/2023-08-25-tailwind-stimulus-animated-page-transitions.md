---
layout: post
title: "Crazy, stupid page transition animation with StimulusJS and TailwindCSS"
author: Yaroslav Shmarov
tags: rails tailwindcss animation page-transition
thumbnail: /assets/thumbnails/tailwindcss.png
---

Here's a very simple page transition animation:

![page transitions with tailwind spin animation](/assets/images/poor-man-page-transition.gif)

When a user clicks a link to redirect to a new page, the `<body>` element gets re-rendered and the stimulus controller gets re-initialized.

```diff
# app/views/layouts/application.html.erb
-<body>
+<body data-controller="transition-animation">
```

```js
// app/javscript/controllers/transition_animation_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="transition-animation"
export default class extends Controller {
  connect() {
    let divs = this.element.querySelectorAll("div")
    // add css class to all <div> elements
    divs.forEach((div) => div.classList.add("animate-spin"))
    // disconnect after 0,5 seconds
    setTimeout(() => {
      // remove css class from all <div> elements
      divs.forEach((div) => div.classList.remove("animate-spin"))
      this.disconnect()
    }, 500)
  }
}
```

`animate-spin` is a TailwindCSS class that represents the following raw css:

```css
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
.animate-spin {
  animation: spin 1s linear infinite;
}
```

That's it! 🤠
