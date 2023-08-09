---
layout: post
title: "TailwindCSS on Rails 02: Responsive dropdown menu"
author: Yaroslav Shmarov
tags: rails tailwindcss
thumbnail: /assets/thumbnails/tailwindcss.png
---

Previously we created a responsive layout: [TailwindCSS on Rails 01: Responsive layout with sidebar]({% post_url 2023-08-07-tailwindcss-layout %})

Now, let's create a dropdown menu that is accessible only on mobile (small screen).

Here's how a perfectly styled mobile menu looks on Superails.com:

![Superails.com dropdown menu](/assets/images/superails-dropdown-menu.gif)

But not so fast! Here's the mobile menu that we will build now: 

![Dropdown menu with TailwindCSS](/assets/images/02-tailwind-dropdown-menu.gif)

First, add a generic stimulus controller to show/hide content:

```js
// app/javasctipt/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.close()
  }

  toggle() {
    if (this.contentTarget.classList.contains("hidden")) {
      this.open()
    }
    else {
      this.close()
    }
  }

  open() {
    this.contentTarget.classList.remove("hidden")
  }

  close() {
    this.contentTarget.classList.add("hidden")
  }
}
```

Now, update the layout file from the previous post:

```diff
<!-- app/views/layouts/application.html.erb -->
<body class="bg-slate-500">
+  <div class="sticky top-0 z-10" data-controller="dropdown">
+    <nav class="bg-slate-200 p-4 flex justify-between items-center h-20">
+      <div class="">
+        logo
+      </div>
+      <div class="flex space-x-2 items-center">
+        <div class="">
+          email
+        </div>
+        <div class=" text-3xl cursor-pointer" data-action="click->dropdown#toggle" role="button">
+          &#9776;
+        </div>
+      </div>
+    </nav>
+    <nav class="absolute hidden bg-green-100 w-full h-80 overflow-y-auto" data-dropdown-target="content">
+      dropdown content
+      <% (200..300).each do |i| %>
+        <p><%= i%></p>
+      <% end %>
+    </nav>
+  </div>
  <div class="bg-slate-300 flex">
    <nav class="bg-slate-400 w-1/6 hidden md:flex flex-col text-center p-4 justify-between sticky top-20 h-[calc(100vh-80px)]">
      <div>
        sidebar top
      </div>
      <div>
        sidebar bottom
      </div>
    </nav>
    <main class="bg-slate-500 w-5/6 p-4 flex-grow">
      main
      <% (1..100).each do |i| %>
        <p><%= i%></p>
      <% end %>
      <%= yield %>
    </main>
  </div>
</body>
```

Notice that the "navbar" (with logo and email) and "dropdown contant" are in the same div;

`absolute` class on "dropdown content", because:
- with - dropdown OVER content
- without - dropdown pushes content down 

Now the layout file is getting really big, so it makes sence to abstract `navbar` and `sidebar` into partials:

```diff
<body class="bg-slate-500">
+  <%= render 'shared/navbar' %>
  <div class="bg-slate-300 flex">
+    <%= render 'shared/sidebar' %>
    <main class="bg-slate-500 w-5/6 p-4 flex-grow">
      main
      <% (1..100).each do |i| %>
        <p><%= i%></p>
      <% end %>
      <%= yield %>
    </main>
  </div>
</body>
```
```

That's it! 🤠

Next steps: 
* Content grid
* Flash message placement, styling, dismissal
* reusable styled error messages
