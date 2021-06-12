---
layout: post
title: 'Rails 6: Install Bootstrap 4 with Yarn and Webpacker: TLDR'
author: Yaroslav Shmarov
tags:
- webpacker
- yarn
- bootstrap
- ruby on rails 6
- ruby on rails
- tldr
thumbnail: /assets/thumbnails/bootstrap.png
---

[See complete version of this article]({% post_url 2020-10-12-rails-6-install-bootstrap-with-webpacker-full %})

# **1. console:**
```
yarn add jquery popper.js bootstrap
mkdir app/javascript/stylesheets
echo > app/javascript/stylesheets/application.scss
```

# **2. environment.js:**

```
const { environment } = require('@rails/webpacker')
const webpack = require("webpack")
environment.plugins.append("Provide", new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    'window.jQuery': 'jquery',
    Popper: ['popper.js', 'default']
  }))
module.exports = environment
```

# **3. add (not replace) in application.html.erb:**
```
= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' 
```
# **4. application.js:**
```
import 'bootstrap/dist/js/bootstrap'
import 'bootstrap/dist/css/bootstrap'
require("stylesheets/application.scss")
```
That's it!😊

****

# **Relevant links**

* [see the official Bootstrap docs here](getbootstrap.com/){:target="blank"}
* [Bootstrap yarn package](https://classic.yarnpkg.com/en/package/bootstrap){:target="blank"}