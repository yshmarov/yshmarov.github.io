---
layout: post
title: "Install Bootstrap 5 with Ruby on Rails 6+"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails bootstrap
thumbnail: https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Bootstrap_logo.svg/768px-Bootstrap_logo.svg.png
---

## Version 1 - fast and easy

console
```
yarn add bootstrap@next
yarn add @popperjs/core
```
application.js
```
import 'bootstrap/dist/js/bootstrap'
import "bootstrap/dist/css/bootstrap";
```

## Version 2 - with stylesheets

console
```
yarn add bootstrap@next
yarn add @popperjs/core
```
application.html.erb
```
<%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
```
application.js
```
import "bootstrap"
import "../stylesheets/application"
```
/app/javascript/stylesheets/application.scss
```
@import "bootstrap"
```

## Version 3 - empty stylesheets

console
```
yarn add bootstrap@next
yarn add @popperjs/core
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
/app/javascript/stylesheets/application.scss
```
//
```

## Bonus: Remove Bootstrap 4

console
```
yarn remove jquery popper.js bootstrap
```
environment.js - only this:
```
const { environment } = require('@rails/webpacker')
module.exports = environment
```

## That's it!
