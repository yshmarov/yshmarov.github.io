---
layout: post
title: "CSS container queries"
author: Yaroslav Shmarov
tags: css tailwindcss
thumbnail: /assets/thumbnails/css.png
---

[Container queries](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_containment/Container_queries) let you create responsive designs based not on screen width, but on parent element width (where `@container` is defined).

Container queries are super easy to use [with TailwindCSS](https://tailwindcss.com/docs/responsive-design#container-queries):

```html
<div class="@container">
  <div class="grid grid-cols-1 @sm:grid-cols-3 @lg:grid-cols-4">
    <!-- ... -->
  </div>
</div>
```

Container queries work out of the box in TailwindCSS 4.

In TailwindCSS 3 you need to install it

```sh
yarn add @tailwindcss/container-queries
```

```diff
// tailwind.atelier.config.js
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
+    require('@tailwindcss/container-queries'),
  ]
```

Amazing new updates:
https://zenn.dev/jun0723/articles/f27b0046072704#コンテナクエリのサポート

field-sizing-content
