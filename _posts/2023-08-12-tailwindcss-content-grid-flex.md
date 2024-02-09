---
layout: post
title: "TailwindCSS on Rails 03: Responsive content layout. Grid, Flex, Center"
author: Yaroslav Shmarov
tags: rails tailwindcss grid flex
thumbnail: /assets/thumbnails/tailwindcss.png
youtube_id: STfxP4YJc6g
---

### Content grid (columns)

```
LG 📜📜📜
MD 📜📜
SM 📜
```

```html
<div id="products" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <%= render @products %>
</div>
```

### Center content on page

```
➡️📜⬅️
```

```html
<div class="mx-auto md:w-2/3 w-full border p-8 rounded-xl shadow-lg">
  <div>
    Element
  </div>
</div>
```

### 2-column layout

```
LG
📜📜
SM
📜
📜
```
Big screen - inline. Small screen - column.

`flex-1` or `flex-grow` - on the `div` within `flex` that should take up the responsive max space in a **row**.

prefer `space-x-4`, `space-y-4` over margins (`ml-4`, `mr-4`, `mt-4`, `m-4`).

prefer `gap-4` over `space-` when possible

```html
<div class="flex flex-col md:flex-row gap-2 bg-rose-200">
  <div class="flex-1 bg-rose-300">
    Element 1
  </div>

  <hr class="my-2">

  <div class="bg-rose-400">
    Element 2
  </div>
</div>
```

### 2-column layout: Fixed width on large screens

use `w-4/5` and similar, instead of `flex-1`:

```html
<div class="flex flex-col lg:flex-row gap-2  bg-green-200">
  <div class="lg:w-4/5 bg-green-300">
    Element 1
  </div>

  <hr class="my-2">

  <div class="lg:ml-4 lg:w-1/5 bg-green-400">
    Element 2
  </div>
</div>
```

### Buttons

* Inline on large screen. 
* Full-width on small screen.

```html
<div class="flex flex-col md:flex-row gap-2">
  <%= link_to 'Edit this product', edit_product_path(@product), class: "rounded-lg py-3 px-5 bg-gray-100" %>
  <%= button_to 'Destroy this product', product_path(@product), method: :delete, class: "w-full rounded-lg py-3 px-5 bg-gray-100" %>
  <%= link_to 'Back to products', products_path, class: "rounded-lg py-3 px-5 bg-gray-100 inline-block" %>
</div>
```

The buttons are imperfect, but not too bad.

That's it! 🤠
