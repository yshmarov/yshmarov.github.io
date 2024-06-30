---
layout: post
title: "TailwindCSS on Rails: Minimize Collapsible Sidebar"
author: Yaroslav Shmarov
tags: rails tailwindcss
thumbnail: /assets/thumbnails/tailwindcss.png
---

A ruby friend named Daniel emailed me a request for this feature:

![email request for this blogpost](/assets/images/tailwind-sidebar-request.png)

Here's my solution, Daniel:

![Tailwind collapsible sidebar](/assets/images/taiwlind-sidebar-toggle-save.gif)

- ✅ Collapsible sidebar
- ✅ Save state
- ✅ Elegant solution

First, create a stimulus controller to collapse sidebar. Write the current state to cookies

```js
// app/javascript/controllers/sidebar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebarContainer"];

  toggle(e) {
    e.preventDefault();
    this.switchCurrentState();
  }

  switchCurrentState() {
    const newState = this.element.dataset.expanded === "true" ? "false" : "true";
    this.element.dataset.expanded = newState;
    document.cookie = `sidebar_expanded=${newState}`;
    // document.cookie = `sidebar_expanded=${newState}; path=/`;
  }
}
```

The toggle can be triggered by a button like this:

```ruby
<%= button_to "Toggle", nil, data: { action: "click->sidebar#toggle" }
```

Toggling the button will update `cookies[:sidebar_expanded]`.

This is accessible in CSS via `[[data-expanded=false]_&]:`. You can use it as a **condition**!

Here's a sidebar that hides text like `"Home"` & `"Buttons"` when `data-expanded=false`:

```html
<!-- app/views/layouts/_sidebar.html.erb -->
<nav class="bg-slate-400 hidden md:flex flex-col text-center p-4 justify-between sticky top-20 h-[calc(100vh-80px)]" data-controller="sidebar" data-expanded="<%= (cookies[:sidebar_expanded] || true) %>">
  <div class="flex flex-col text-left">
    <%= link_to root_path do %>
      <span>🏠</span>
      <span class="[[data-expanded=false]_&]:hidden">Home</span>
    <% end %>
    <%= link_to buttons_path do %>
      <span>🔘</span>
      <span class="[[data-expanded=false]_&]:hidden">Buttons</span>
    <% end %>
  </div>
  <div class="text-left">
    <%= button_to nil, data: { action: "click->sidebar#toggle" } do %>
      <span class="[[data-expanded=true]_&]:hidden">➡️</span>
      <span class="[[data-expanded=false]_&]:hidden">⬅️</span>
      <span class="[[data-expanded=false]_&]:hidden">Toggle</span>
    <% end %>
  </div>
</nav>
```

🤠 Voila!
