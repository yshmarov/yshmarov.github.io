---
layout: post
title: "RGB complimentary colors (opposite colors) in Ruby"
author: Yaroslav Shmarov
tags: ruby rails
thumbnail: /assets/thumbnails/rgb.png
---

Recently I've been intrigued by generating random colors and their opposites [complementary colors](https://en.wikipedia.org/wiki/Complementary_colors).

Here's what I came up with for generating radom RGB colors and their opposites:

![random-rgb-color-and-opposite.gif](/assets/images/random-rgb-color-and-opposite.gif)

Considering that an RGB consists of 3 values within 0 and 255, we can just generate these 3 values:

```ruby
# app/helpers/random_color_helper.rb
module RandomColorHelper
  def color_and_opposite
    color = random_rgb
    opposite_color = invert_rgb(color)
    { color:, opposite_color: }
  end

  def random_rgb
    r = rand(0..255)
    g = rand(0..255)
    b = rand(0..255)
    [r, g, b].join(',')
  end

  # invert_rgb(random_rgb)
  def invert_rgb(color)
    color = color.split(',')
    color = color.map(&:to_i)
    r = 255 - color[0]
    g = 255 - color[1]
    b = 255 - color[2]
    [r, g, b].join(',')
  end
end
```

For a view, be sure to instantiate the `color_and_opposite` method from the controller, so that you do it once and get the correct color-opposite pair:

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @color_and_opposite = helpers.color_and_opposite
  end
end
```

Display color and opposite in a view:

```html
<div style="background-color: rgb(<%= @color_and_opposite[:color] %>); color: rgb(<%= @color_and_opposite[:opposite_color] %>)">
  <div>
    Color: <%= @color_and_opposite[:color] %>
  </div>
  <div>
    Opposite: <%= @color_and_opposite[:opposite_color] %>
  </div>
</div>
```

For a more sophisticated solution you can try using [gem color-generator](https://github.com/jpmckinney/color-generator).

That's it! 🚀