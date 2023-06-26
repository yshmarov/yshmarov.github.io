---
layout: post
title: "SVG in Rails. Gem inline_svg"
author: Yaroslav Shmarov
tags: ruby-on-rails inline_svg svg
thumbnail: /assets/thumbnails/html.png
---

In some cases you don't want to use external SVG libraries like
[FontAwesome]({% post_url 2022-04-10-fontawesome-importmaps-rails7 %}){:target="blank"}

Instead, you might want to use your own SVGs.

You can import SVGs into your apps' assets folder:

```html
<!-- app/assets/images/svg/search.svg -->
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M15.828 14.871l-4.546-4.545a6.34 6.34 0 10-.941.942l4.545 4.545a.666.666 0 00.942-.942zm-9.461-3.525a4.995 4.995 0 114.994-4.994 5 5 0 01-4.994 4.994z" fill="#272727"/>
</svg>
```

BTW, usually when I import an SVG, I:
* set `fill` to `currentColor`
* width/height in `em` instead of `px`
* remove `style` and `class` attributes

```diff
-fill="#FFFFFF"
+fill="currentColor"
```

```diff
-width="16px" height="16px"
+width="1em" height="1em"
```

The final SVG that is ready to be used in the app will look like this:

```html
<!-- app/assets/images/svg/search2.svg -->
<svg width="1em" height="1em" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M15.828 14.871l-4.546-4.545a6.34 6.34 0 10-.941.942l4.545 4.545a.666.666 0 00.942-.942zm-9.461-3.525a4.995 4.995 0 114.994-4.994 5 5 0 01-4.994 4.994z" fill="currentColor"/>
</svg>
```

To display the SVG, you can try to use `image_tag` and render the SVG as an **image**:

```ruby
<%= image_tag "svg/search.svg", style: "color: green; background-color: red; height: 50px; width: 20px;" %>
<%= image_tag "svg/search2.svg", style: "color: green; background-color: red; height: 50px; width: 20px;" %>
<%= image_tag "svg/search2.svg", style: "color: green; background-color: red; font-size: 40px;" %>
```

And here we see the problem: we can't style the SVGs with CSS `class` & `style`:

![svg-as-img](/assets/images/svg-as-img.png)

To overcome this issue, we can use a helper that will parse an SVG, add html options and render it in html:

```ruby
# app/helpers/svg_helper.rb
module SvgHelper
  def svg_tag(icon_name, options={})
    file = File.read(Rails.root.join('app', 'assets', 'images', 'svg', "#{icon_name}.svg"))
    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css 'svg'

    options.each {|attr, value| svg[attr.to_s] = value}

    doc.to_html.html_safe
  end
end
```

```ruby
<%= svg_tag 'search', style: "color: green; background-color: red; height: 50px; width: 20px;" %>
<%= svg_tag 'search2', style: "color: green; background-color: red; height: 50px; width: 20px;" %>
<%= svg_tag 'search2', style: "color: green; background-color: red; font-size: 40px;" %>
```

Now you see that the SVG was **correctly** rendered as an SVG in HTML:

![svg-as-svg](/assets/images/svg-as-svg.png)

Finally, instead of writing custom SVG helpers and "reinventing the wheel", you can use an out-of-the-box solution: [`gem inline_svg`](https://github.com/jamesmartin/inline_svg){:target="blank"}

```shell
# terminal
bundle add inline_svg
```

```ruby
<%= inline_svg_tag 'svg/search', style: "color: green; background-color: red; height: 50px; width: 20px;" %>
<%= inline_svg_tag 'svg/search2', style: "color: green; background-color: red; height: 50px; width: 20px;" %>
<%= inline_svg_tag 'svg/search2', style: "color: green; background-color: red; font-size: 40px;" %>
```

### Display all svgs in a view

```ruby
class StyleguideController < ApplicationController
  def index
    @svg_names = Rails.root.join("app", "assets", "images", "svg").children.map { |path| path.basename.to_s.split(".")[0] }
  end
end
```

```ruby
<% @svg_names.each do |svg_name| %>
  <%= inline_svg_tag "svg/#{svg_name}.svg", class: "h-6 w-6" %>
  <%= svg_name %>
<% end %>
```

That's it!

References:
* [Sean C Davis: Render inline SVG in Rails](https://www.seancdavis.com/posts/render-inline-svg-rails-middleman/){:target="blank"}
* [d1vplg: Embedding and styling SVG in Rails](https://coderwall.com/p/d1vplg/embedding-and-styling-inline-svg-documents-with-css-in-rails){:target="blank"}
* [hslzr: Use inline svgs in Rails](https://dev.to/hslzr/using-inline-svgs-with-rails-3khb){:target="blank"}
* [Zondicons SVG library](https://www.zondicons.com/){:target="blank"}
* [FontAwesome SVG library](https://www.zondicons.com/){:target="blank"}
