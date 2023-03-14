---
layout: post
title:  Style default error pages in a Rails app
author: Yaroslav Shmarov
tags: ruby-on-rails, error-pages, 404
thumbnail: /assets/thumbnails/404.png
---

Previously I wrote about adding [Custom error pages in a Rails app]({%post_url 2020-12-14-custom-error-pages %}). If you don't want to go that way, you can just style the existing error pages that are stored in the `/public` folder with CSS.

Here is some example CSS styling I did for a page:

![styled 404 page](/assets/images/styled-404-page.png)

Feel free to copy my `public/404.html` and use it in your app:

```html
<!DOCTYPE html>
<html>
<head>
  <title>The page you were looking for doesn't exist (404)</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    .rails-default-error-page {
      background-color: white;
      color: #2E2F30;
      text-align: center;
      font-family: arial, sans-serif;
    }
    .button-home {
      font-size: 20px;
      color: white;
      text-decoration: none;
      background-color: #008060;
      padding-left: 14px;
      padding-right: 14px;
      padding-top: 6px;
      padding-bottom: 6px;
      border-radius: 4px;
      box-shadow: 0px 1px 0px rgba(0, 0, 0, 0.08), inset 0px -1px 0px rgba(0, 0, 0, 0.2);
      display: inline-block;
    }
    .button-help {
      font-size: 20px;
      color: black;
      text-decoration: none;
      border: 1px solid;
      border-color: #BABFC3;
      padding-left: 14px;
      padding-right: 14px;
      padding-top: 6px;
      padding-bottom: 6px;
      border-radius: 4px;
      box-shadow: 0px 1px 0px rgba(0, 0, 0, 0.05);
      display: inline-block;
    }
    .container {
      position: relative;
      text-align: center;
    }
    .centered {
      position: absolute;
      top: 80%;
      left: 50%;
      transform: translate(-50%, -50%);
    }
  </style>
</head>

<body class="rails-default-error-page">
  <div class="container">
    <img src="404logo.png" alt="mylogo">
    <div class="centered" style="font-size: 96px; font-weight: 900;">
      404.
    </div>
  </div>
  <div style="font-size: 28px; font-weight: bold;">
    Page not found
  </div>
  <div style="margin-top: 20px; margin-bottom: 14px;">
    <a href="/" class="button-home">Back to home page</a>
  </div>
  <div>
    <a href="https://superails.com/" target="_blank" class="button-help">Visit help center</a>
  </div>
</body>
</html>
```

To make it look nice, be sure to have a `public/404logo.png` file present.

Here is the image I use. Please do not reuse it!

![404 facial expression](/assets/images/404logo.png)

Hope this post helps you to build faster!
