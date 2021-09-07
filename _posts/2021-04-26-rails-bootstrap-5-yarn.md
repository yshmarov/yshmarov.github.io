---
layout: post
title: "Install Bootstrap 5 with Ruby on Rails 6+"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails bootstrap
thumbnail: /assets/thumbnails/bootstrap.png
---

## Important: use `@popperjs/core`, not `popper.js`

## Option 1

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

app/javascript/packs/application.js

```
import 'bootstrap/dist/js/bootstrap'
import 'bootstrap/dist/css/bootstrap'
import 'stylesheets/application'
```

Serve all your stylesheets via webpacker. Keep styles inside the /javascript folder.

Example:

/superdemo/app/javascript/stylesheets/application.scss
```
body { background-color: #ede3d5; }
```

## Option 2

app/views/layouts/application.html.erb

```
<%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
```

app/javascript/packs/application.js
```
import 'bootstrap'
import "../stylesheets/application"
```

/superdemo/app/javascript/stylesheets/application.scss
```
@import "bootstrap";
```

## Option 3

app/views/layouts/application.html.erb

```
<%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
```

app/javascript/packs/application.js

```
import * as bootstrap from 'bootstrap'
import "../stylesheets/application"
```

app/javascript/stylesheets/application.scss

```
@import "bootstrap"
```

## Bonus: Remove jQuery (needed for B4 but not B5)

console
```
yarn remove jquery popper.js
```
environment.js - leave only this:
```
const { environment } = require('@rails/webpacker')
module.exports = environment
```

## That's it!
