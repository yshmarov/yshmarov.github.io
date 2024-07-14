---
layout: post
title: "TailwindCSS on Rails: Dark Mode"
author: Yaroslav Shmarov
tags: rails tailwindcss dark-mode
thumbnail: /assets/thumbnails/tailwindcss.png
---

Previously I wrote about implementing [Dark Mode with pure CSS]({% post_url 2020-09-21-ruby-on-rails-dark-mode %}).

#### 1. Dark mode CSS

To implement Dark Mode with TailwindCSS, you simply use the `dark:` variant.

```html
<div class="bg-white text-black dark:bg-black dark:text-white>
</div>
```

This way the dark mode will be set based on your **system preferences**:

![dark-mode-system-preferences](/assets/images/dark-mode-system-preferences.png)

#### 2. Default to dark mode

To manually set the app to dark mode add this line to the tailwind config file:

```diff
# config/tailwind.config.js
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
+  darkMode: 'class',
```

Next, add the `dark` class to your document:

```diff
# app/views/layouts/application.html.erb
<!DOCTYPE html>
-<html class="">
+<html class="dark">
```

Now, all the `dark:` classes will be applied by default!

#### 3. Toggle dark mode

You can use JS to add/remove the `dark` class from the document.

You can store the users' choice in the database, or in the **cookies** (localStorage).

Let's use StimulusJS for this

```shell
rails g stimulus theme
```

```js
// app/javascript/controllers/theme_controller.js
import { Controller } from "@hotwired/stimulus"

// <div data-controller="theme">
//   <%= button_to "🌞 Light", "#", data: { action: "theme#light" } %>
//   <%= button_to "🌙 Dark", "#", data: { action: "theme#dark" } %>
// </div>

// Connects to data-controller="theme"
export default class extends Controller {
  connect() {
    if (localStorage.getItem('theme') === 'dark') {
      this.dark();
    }
  }

  dark(e) {
    e.preventDefault();
    localStorage.setItem('theme', 'dark');
    document.documentElement.classList.add('dark');
  }

  light(e) {
    e.preventDefault();
    localStorage.removeItem('theme');
    document.documentElement.classList.remove('dark');
  }
}
```

Final result:

![toggle dark mode](/assets/images/toggle-dark-mode.gif)

If you want to go deeper and set `[:light, :dark, :system_default]` varians, you can read these:
- [Tailwind: dark mode](https://tailwindcss.com/docs/dark-mode)
- [Flowbite: dark mode](https://flowbite.com/docs/customize/dark-mode/)
