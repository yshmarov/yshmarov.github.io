---
layout: post
title: Render Markdown FILES in Rails app
author: Yaroslav Shmarov
tags: rails markdown
thumbnail: /assets/thumbnails/markdown.png
---

I love this new era of ultra-simplified websites.

PlanetScale uses MARKDOWN for its' marketing pages.

![planetscale uses markdown for marketing pages](/assets/images/prefer-markdown.png)

Focus on delivering the value, not the flashy animations! 🎯

And you can be MUCH more productive with Markdown than with HTML!

Here's how you can render markdown **files** in your Rails app:

Add [gem redcarpet](https://github.com/vmg/redcarpet)

```ruby
# console
bundle add redcarpet
```

Create a helper to parse markdown to HTML:

```ruby
# app/helpers/application_helper.rb
  def markdown_to_html(markdown_text)
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    markdown.render(markdown_text).html_safe
  end
```

Finally, render the markdown file in a Rails view!

For TailwindCSS, wrap it in `class="prose"`.

```html
<!-- render README.md in any view -->
  <div class="prose">
    <%= markdown_to_html(File.read(Rails.root.join('README.md'))) %>
  </div>
```

Learn more about [Markdown with Redcarpet]({% post_url 2021-06-10-markdown %}) and [Code syntax highlighting with gem Rouge]({% post_url 2021-07-06-markdown-styling-with-rouge %})
