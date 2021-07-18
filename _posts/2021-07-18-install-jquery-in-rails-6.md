---
layout: post
title: "Ruby on Rails 6+: install jQuery with yarn and webpacker"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails jquery webpacker yarn
thumbnail: /assets/thumbnails/jquery.png
---

With Rails 6+ usage of webpacker, Stimulus.js and jQuery not being a dependency of Bootstrap 5+, 
jQuery is slowly becoming an undesirable feature in new Rails applications. 

However there still are many great libraries that are based on jQuery that you may want to make use of.

Here's the simple way to install jQuery in Rails 6:

console

```
yarn add jquery
```

config/environment.js

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

That's it!
