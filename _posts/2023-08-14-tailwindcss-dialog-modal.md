---
layout: post
title: "Modals with HTML dialog element, TailwindCSS and StimulusJS"
author: Yaroslav Shmarov
tags: rails dialog modal tailwindcss
thumbnail: /assets/thumbnails/tailwindcss.png
---

Safari has finally adopted the [`<dialog>` HTML element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog), and now it is supported by all browsers!

HTML `<dialog>` is basically a "modal":
* centered on page by default
* disables background clicks when open
* can be closed with native HTML (without extra JS)
* includes CSS to blur/dim background by default
* can be closed with Escape key

Example:

![open-close-html-dialog-modal](/assets/images/open-close-html-dialog-modal.gif)

#### Display basic dialog:

```html
<dialog open>
  <span>You can see me</span>
</dialog>
```

#### Dialog with "Close" button (without submitting form):

`method="dialog"` on form

```html
<dialog open>
  <span>You can see me</span>
  <form method="dialog">
    <button type="submit" autofocus>Cancel</button>
  </form>
</dialog>
```

#### Dialog with both "Close" button and regular "Submit" button on form:

`formmethod="dialog"` on button

```html
<dialog open>
  <span>You can see me</span>
  <form>
    abc
    <button formmethod="dialog" type="submit">Cancel</button>
    <button>Submit</button>
  </form>
</dialog>
```

#### With button to open modal:

```html
<div data-controller="dialog">
  <button data-action="dialog#open">
    Open modal
  </button>

  <dialog data-dialog-target="modal">
    <span>You can see me</span>
    <form method="dialog">
      <button type="submit" autofocus>Cancel</button>
    </form>
  </dialog>
</div>
```

```js
// app/javascript/controllers/dialog_controller.js
static targets = ["modal"]

open() {
  this.modalTarget.showModal()
  // this.modalTarget.show()
}
```

- `.show()` - background is clickable, can be used like a regular dropdown
- `.showModal()` - background is not clickable, you can apply css styles like `blur`. You can use "Esc" key close it!

Most likely you want to use exclusively `.showModal()`.

#### Background blur, color, opacity

```css
dialog::backdrop {
  backdrop-filter: blur(8px);
  background-color: hsl(250, 100%, 50%, 0.25);
}
```

#### Close on click outside

```js
  clickOutside(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
```

```diff
-<div data-controller="dialog">
+<div data-controller="dialog" data-action="click->dialog#clickOutside">
```

#### Disable background scrolling when dialog is open

```js
  open() {
    this.dialogTarget.showModal()
    document.body.classList.add("overflow-hidden");
  }

  close() {
    this.dialogTarget.close()
    document.body.classList.remove("overflow-hidden");
  }
```

Important: It will not work with the default behaviour of closing by clicking `Escape` or by `method="dialog"`.

To make it actually work you need to **listen** to the `close` event on `<dialog>`:

```js
  connect() {
    this.modalTarget.addEventListener("close", this.enableBodyScroll.bind(this))
  }

  enableBodyScroll() {
    document.body.classList.remove('overflow-hidden')
  }
```
#### Blur background

```css
/* app/assets/stylesheets/application.css */
dialog::backdrop {
  backdrop-filter: blur(8px);
  /* background-color: hsl(250, 100%, 50%, 0.25); */
}
```

#### Final result

- ✅ Styled modal
- ✅ Blur background
- ✅ Close on Escape
- ✅ Close on click outside
- ✅ Close on clicking button

![open-close-html-dialog-modal](/assets/images/open-close-html-dialog-modal.gif)

```html
<div data-controller="dialog" data-action="click->dialog#clickOutside">
  <button data-action="click->dialog#open">Open dialog</button>
  <dialog data-dialog-target="modal"
          class="backdrop:bg-gray-400 backdrop:bg-opacity-90 z-10 rounded-md border-4 bg-sky-900 w-full md:w-2/3 mt-24">
    <div class="p-8">
      <button class="bg-slate-400" data-action="dialog#close">Cancel</button>
      <p>Greetings, one and all!</p>
      <form>
        <button formmethod="dialog">Cancel</button>
        <button>OK</button>
      </form>
    </div>
  </dialog>
</div>
```

```js
// app/javascript/controllers/dialog_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.modalTarget.addEventListener("close", this.enableBodyScroll.bind(this))
  }

  disconnect() {
    this.modalTarget.removeEventListener("close", this.enableBodyScroll.bind(this))
  }

  open() {
    // this.modalTarget.show()
    this.modalTarget.showModal()
    document.body.classList.add('overflow-hidden')
  }

  close() {
    this.modalTarget.close()
    // document.body.classList.remove('overflow-hidden')
  }

  enableBodyScroll() {
    document.body.classList.remove('overflow-hidden')
  }

  clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}
```

Inspired by:
* https://blog.webdevsimplified.com/2023-04/html-dialog/
* https://dev.to/thomasvanholder/create-a-modal-with-the-html-dialog-element-tailwind-and-stimulus-573b

To explore in the future:
- submitting a form with errors
- submitting a form with `format.html`, `format.turbo_stream`

That's it for now! 🤠
