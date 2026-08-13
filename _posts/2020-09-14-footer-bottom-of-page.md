---
layout: post
title: "Quick tip: Footer on the bottom of the page: TLDR"
author: Yaroslav Shmarov
tags: ruby-on-rails tldr footer html css
thumbnail: /assets/thumbnails/css.png
---

Here's a simple way to keep the footer on the bottom of the page with minimum modifications.

👍 fixed to the end of the page

👍 dynamic height

👍 responsive

👍 not sticky

We are keeping `footer` outside `body`:

```
# application.html
<!DOCTYPE html>
<html>
  <head></head>
  <body></body>
  <footer></footer>
</html>
```

```
# application.scss

html {
    margin: 0;
}

body {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
}

footer {
    margin-top: auto;
}
```

That's it! 🤠
