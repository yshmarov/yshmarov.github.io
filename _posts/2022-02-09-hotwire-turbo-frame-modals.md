---
layout: post
title: "#21 Hotwire Turbo: The one right way to do Modals"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo tldr modals tailwind viewcomponent
thumbnail: /assets/thumbnails/turbo.png
canonical_url: https://www.bearer.com/blog/how-to-build-modals-with-hotwire-turbo-frames-stimulusjs
---

The **MOST** important thing about handling a modals **CORRECTLY** - closing it only when the form submission is successful with `turbo:submit-end`.

[Full version of this article (also written by me for Bearer.com)](https://www.bearer.com/blog/how-to-build-modals-with-hotwire-turbo-frames-stimulusjs){:target="blank"}

![good-modal-example](/assets/images/good-modal-example.gif)

Stack:
* Rails 7 with Hotwire
* ViewComponent
* TailwindCSS

**HOWTO:**

Add a modal that is available globally:

```ruby
# app/views/layouts/application.html.erb
  <%= turbo_frame_tag "modal" %>
```

Modal component:

```ruby
# app/components/turbo_modal_component.html.erb
<%= turbo_frame_tag "modal" do %>
  <%= tag.div data: { controller: "turbo-modal",
                      turbo_modal_target: "modal",
                      action: "turbo:submit-end->turbo-modal#submitEnd keyup@window->turbo-modal#closeWithKeyboard click@window->turbo-modal#closeBackground" },
                      class: "p-5 bg-slate-300 absolute z-10 top-10 right-10 rounded-md w-96 break-words" do %>
    <h1 class="font-bold text-4xl"><%= @title %></h1>
    <%= yield %>
    <%= button_tag "Close", data: { action: "turbo-modal#hideModal" }, type: "button", class: "rounded-lg py-3 px-5 bg-red-600 text-white" %>
  <% end %>
<% end %>
```

*Alternatively to ViewComponent you can just use a partial. [Here's how]({% post_url 2022-02-02-partials-to-simplify-views %})*

Wrap views that should be rendered in a modal into the Modal component:

```ruby
# app/views/posts/new.html.erb
<%= render TurboModalComponent.new(title: "New Post:") do %>
  <%= render "form", post: @post %>
<% end %>
```

```ruby
# app/views/posts/edit.html.erb
<%= render TurboModalComponent.new(title: "Editing Post") do %>
  <%= render "form", post: @post %>
<% end %>
```

Stimulus controller to handle form submission & common modal behavior:

```js
// app/javascript/controllers/turbo_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  // hide modal
  // action: "turbo-modal#hideModal"
  hideModal() {
    this.element.parentElement.removeAttribute("src")
    // Remove src reference from parent frame element
    // Without this, turbo won't re-open the modal on subsequent click
    this.modalTarget.remove()
  }

  // hide modal on successful form submission
  // action: "turbo:submit-end->turbo-modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.hideModal()
    }
  }

  // hide modal when clicking ESC
  // action: "keyup@window->turbo-modal#closeWithKeyboard"
  closeWithKeyboard(e) {
    if (e.code == "Escape") {
      this.hideModal()
    }
  }

  // hide modal when clicking outside of modal
  // action: "click@window->turbo-modal#closeBackground"
  closeBackground(e) {
    if (e && this.modalTarget.contains(e.target)) {
      return;
    }
    this.hideModal()
  }
}
```

Final step - add `data: { turbo_frame: 'modal' }` to links to `Create` and `Edit`.

```ruby
# app/views/posts/index.html.erb
<%= button_to 'New post', new_post_path, method: :get, data: { turbo_frame: 'modal' }, class: "rounded-lg py-3 px-5 bg-blue-600 text-white block font-medium" %>
```

That's it! [Source code](https://github.com/corsego/63-hotwire-modals){:target="blank"}

What can be improved here:
* conditionally blur background
* conditionally center modal