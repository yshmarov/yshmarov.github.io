---
layout: post
title: "Revised: Hotwire Turbo Modals with HTML Dialog"
author: Yaroslav Shmarov
tags: hotwire turbo modals dialog
thumbnail: /assets/thumbnails/turbo.png
---

Previously I wrote about:

1) [Hotwire Turbo Modals]({% post_url 2022-02-09-hotwire-turbo-frame-modals %}){:target="blank"}

2) [HTML Modals with Dialog element]({% post_url 2023-08-14-tailwindcss-dialog-modal %}){:target="blank"}

We can combine the two to make the perfect modals!

Requirements:
- leverage HTML `<dialog>` (default styling, close behaviours)
- turbo frames: dynamic modal content, navigation
- handle form validation errors
- conditionally close modal after successful form submit
- respond with turbo_steam/redirect/turbo_frame refresh

Working example:

![turbo modal with html dialog element](/assets/images/turbo-dialog-modal-demo.gif)

We will import `dialog_controller.js` from [the previous post]({% post_url 2023-08-14-tailwindcss-dialog-modal %}).

Additionally to handle turbo frames, we will:
* add a `frame_target` that we clean up when dialog is closed
* add `submitEnd` that is fired when a form is submitted successfully

```diff
// app/javascript/controllers/dialog_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
export default class extends Controller {
-  static targets = ["modal"]
+  static targets = ["modal", "frame"]

  connect() {
    this.modalTarget.addEventListener("close", this.enableBodyScroll.bind(this))
  }

  disconnect() {
    this.modalTarget.removeEventListener("close", this.enableBodyScroll.bind(this))
  }

  open() {
    this.modalTarget.showModal()
    document.body.classList.add('overflow-hidden')
  }

+ submitEnd(e) {
+   if (e.detail.success) {
+     this.close()
+   }
+ }

  close() {
    this.modalTarget.close()
    // clean up the frame
+    this.frameTarget.removeAttribute("src")
+    this.frameTarget.innerHTML = ""
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

Add dialog to layout to enable access to it globally.
* `data-controller="dialog"` should be on `<body>`, so that `click->dialog#open` works anywhere
* Empty `turbo_frame_tag :modal` inside `<dialog>`
* `data: {dialog_target: "frame"}` needed to remove content from frame when dialog is closed

```ruby
# app/views/layouts/application.html.erb
<body data-controller="dialog" data-action="click->dialog#clickOutside">
  <dialog data-dialog-target="modal"
          class="backdrop:bg-gray-400 backdrop:bg-opacity-90 z-10 rounded-md border-4 bg-sky-900 w-full md:w-2/3 mt-24">
    <div class="p-8">
      <button class="font-bold float-right" data-action="dialog#close">X</button>
      <%= turbo_frame_tag :modal, data: {dialog_target: "frame"} %>
    </div>
  </dialog>

  <main class="">
    <button data-action="click->dialog#open">Open dialog</button>
    <%= yield %>
  </main>
</body>
```

Now you can add `data: { turbo_frame: :modal, action: "dialog#open" }` to any link in your app. It will:

1) open dialog

2) replace the content of `turbo_frame: :modal` with content from the rendered page

```ruby
<%= link_to 'Add comment', new_comment_path, data: { turbo_frame: :modal, action: "dialog#open" } %>
```

- `Content missing`?
- => Wrap the page into `turbo_frame_tag :modal`

- Modal does not close after successful form submit?
- => add `data-action="turbo:submit-end->dialog#submitEnd"` to ensure that dialog is closed after successful form submit

```diff
# comments/new.html.erb
+<%= turbo_frame_tag :modal do %>
  <h1 class="font-bold text-4xl">New comment</h1>
+  <div data-action="turbo:submit-end->dialog#submitEnd">
    <%= render "form", comment: @comment %>
+  </div>
+<% end %>
```

### Refactoring

Problems with the above approach:
- We were needlessly adding a stimulus controller on the BODY html tag;
- dialog html was present in the layout file, even if we do not need it right now;

Solution:

Let's remove the `<dialog>` from the layout file, and leave an empty `turbo_frame_tag :modal`

```diff
# app/views/layouts/application.html.erb
  <body>
    <%= turbo_frame_tag :modal %>
    <%= yield %>
  </body>
```

We will open

```ruby
# app/views/layouts/_turbo_dialog.html.erb
<%= turbo_frame_tag :modal do %>
  <dialog data-controller="dialog" data-action="click->dialog#clickOutside"
          class="backdrop:bg-gray-400 backdrop:bg-opacity-90 z-10 rounded-md border-4 bg-sky-900 w-full md:w-2/3 mt-24">
    <div class="p-8">
      <button class="bg-slate-400" data-action="dialog#close">Cancel</button>

      <%= yield %>

    </div>
  </dialog>
<% end %>
```

Wrap the views that should be rendered inside the modal with the new `_turbo_dialog` partial:

```diff
# app/views/comments/new.html.erb
# app/views/comments/edit.html.erb
# app/views/comments/show.html.erb
- <%= turbo_frame_tag :modal do %>
+ <%= render 'layouts/turbo_dialog' do %>
```

So now when a user clicks on a link that should open inside a modal, the content will be rendered within a hidden `<dialog>`. Let's update the stimulus controller to automatically open this dialog:

```diff
// app/javascript/controllers/dialog_controller.js
// app/javascript/controllers/dialog_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
export default class extends Controller {
  connect() {
+    this.open()
    // needed because ESC key does not trigger close event
    this.element.addEventListener("close", this.enableBodyScroll.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("close", this.enableBodyScroll.bind(this))
  }

  // hide modal on successful form submission
  // data-action="turbo:submit-end->turbo-modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.close()
    }
  }

  open() {
    this.element.showModal()
    document.body.classList.add('overflow-hidden')
  }

  close() {
    this.element.close()
    // clean up modal content
+    const frame = document.getElementById('modal')
+    frame.removeAttribute("src")
+    frame.innerHTML = ""
  }

  enableBodyScroll() {
    document.body.classList.remove('overflow-hidden')
  }

  clickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
```

We also cleaned up the redundant stimulus targets!

Perfect! Visually everything works the same, but this code is much better! 🎯

### Disable certain pages to be opened outside modal

```ruby
# app/controllers/comments_controller.rb
  before_action :ensure_frame_response, only: [:new, :create, :edit, :update]

  def ensure_frame_response
    redirect_to root_path unless turbo_frame_request?
  end
```

### Testing turbo frame requests

```ruby
get new_comment_path, headers: {"Turbo-Frame" => "new_comment"}
assert_response :success

post comment_path(comment), params: {comment: {body: 'foo'}}, headers: {"Turbo-Frame" => "new_comment"}
assert_response :success
```

Well, that's it! 

This approach works well for hotwire-based modals.

[Source code](https://github.com/corsego/151-dialog-turbo-modals/commits/main)
