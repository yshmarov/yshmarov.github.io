---
layout: post
title: "Rails enums - different approaches"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails enums
thumbnail: /assets/thumbnails/select-options.png
---

*Problem*: Make popovers work with turbolinks and code input
*Tech stack*:
* Bootstrap 4 with jQuery
* Rails 6
* Haml
* fontawesome

application.js
```
import $ from 'jquery'
document.addEventListener("turbolinks:load", () =>
  $(function () {
    $('[data-toggle="popover"]').popover({
    html: true,
    trigger: 'hover',
    content: function () {
      return $(this).data('content');
    }
  });
}));

any view:
```
%i.fas.fa-info-circle{data: {content: "#{User.count}", toggle: "popover", title: "Type of refurbishment required details"}, type: "button" }
```
or
```
%div{data: {content: "#{User.count}", toggle: "popover", title: "Type of refurbishment required details"}, type: "button" } click here
```