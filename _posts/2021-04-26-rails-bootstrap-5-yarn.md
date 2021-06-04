---
layout: post
title: "Install Bootstrap 5 with Ruby on Rails 6+"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails bootstrap
thumbnail: https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Bootstrap_logo.svg/768px-Bootstrap_logo.svg.png
---

console
```
yarn add bootstrap
yarn add @popperjs/core
mkdir app/javascript/stylesheets
echo > app/javascript/stylesheets/application.scss
```
application.html.erb
```
<%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
```
application.js
```
import 'bootstrap/dist/js/bootstrap'
import "bootstrap/dist/css/bootstrap";
import "../stylesheets/application"
```

## Bonus: Remove Bootstrap 4

console
```
yarn remove jquery popper.js bootstrap
```
environment.js - leave only this:
```
const { environment } = require('@rails/webpacker')
module.exports = environment
```

## That's it!
