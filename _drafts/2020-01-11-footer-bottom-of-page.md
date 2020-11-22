---
layout: post
title: "Quick tip: Footer on the bottom of the page: TLDR"
date: '2020-11-06T13:55:00.007+01:00'
author: yaro_the_slav
tags: 
- footer
- html
- css
- ruby on rails
---

Here's a simple way to keep the footer on the bottom of the page with minimum modifications.

👍 fixed to the end of the page

👍 dynamic height

👍 responsive

👍 not sticky

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
