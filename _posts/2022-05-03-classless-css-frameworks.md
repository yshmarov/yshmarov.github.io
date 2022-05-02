---
layout: post
title: 'Classless CSS frameworks'
author: Yaroslav Shmarov
tags: rails html css
thumbnail: /assets/thumbnails/css.png
---

When building a small website or rails app, sometimes adding a CSS framework and styling your pages can be a time-consuming overkill.

Luckily there exist **Classless CSS frameworks** like [SimpleCSS](https://simplecss.org/) or [MVP.CSS](https://andybrewer.github.io/mvp/).

A classless CSS frameworks directly styles HTML attributes.

```html
<!-- Tailwind CSS -->
<body class="border-s rounded-m p-16 shadow-l">
<!-- Bootstrap CSS -->
<body class="container">
<!-- Classless CSS -->
<body>
```

So if you write **semantic HTML**, when adding a classless CSS framework, the styling will be applied automatically!

Just include the CDN in your layout:

```diff
# app/views/layouts/application.html.erb
<head>
    ...
+  <link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
</head>
```

Result:

![semantic html with a classless css framework](/assets/images/classless-css-semantic-html.png)

Also, if you read the actual [CSS file that you import](https://cdn.simplecss.org/simple.css), you can learn some great practices to writing CSS.

Thinking further, you can potentially swap classless CSS frameworks in your app like **themes**!...

There's also [a great discussion about classless css frameworks on ycombinator news](https://news.ycombinator.com/item?id=29929438)
