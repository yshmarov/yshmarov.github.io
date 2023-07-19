---
layout: post
title:  Style default error pages in a Rails app
author: Yaroslav Shmarov
tags: ruby-on-rails, error-pages, 404
thumbnail: /assets/thumbnails/404.png
---

Series:
1. [Add custom error pages in a Rails app]({% post_url 2023-03-14-style-default-error-pages %})
2. [Style default error pages in a Rails app inside /public folder]({% post_url 2023-03-14-style-default-error-pages %})
3. [DRY custom error pages]({% post_url 2023-07-19-dry-custom-error-pages %})

Previously I wrote about adding [Adding custom error pages in a Rails app]({%post_url 2020-12-14-custom-error-pages %}). If you don't want to go that way, you can just style the existing error pages that are stored in the `/public` folder with CSS.

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
    .button {      
      font-size: 14px;
      text-decoration: none;
      padding-left: 16px;
      padding-right: 16px;
      padding-top: 7px;
      padding-bottom: 7px;
      border-radius: 4px;
      display: inline-block;
    }
    .button-home {
      color: white;
      background-color: #008060;
      box-shadow: 0px 1px 0px rgba(0, 0, 0, 0.08), inset 0px -1px 0px rgba(0, 0, 0, 0.2);
    }
    .button-help {
      color: black;
      border: 1px solid;
      border-color: #BABFC3;
      box-shadow: 0px 1px 0px rgba(0, 0, 0, 0.05);
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
    <a href="/" class="button button-home">Back to home page</a>
  </div>
  <div>
    <a href="https://superails.com/" target="_blank" class="button button-help">Visit help center</a>
  </div>
</body>
</html>
```

You can use the same template for `/422.html` and `/500.html`, just change the text.

To make it look nice, be sure to have a `public/404logo.png` file present.

Here is the image I use. Please do not reuse it!

![404 facial expression](/assets/images/404logo.png)

Hope this post helps you to build faster!
