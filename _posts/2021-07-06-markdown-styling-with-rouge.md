---
layout: post
title: "Markdown Level 2. Style markdown css with gem Rouge"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails markdown redcarpet rouge
thumbnail: /assets/thumbnails/markdown.png
youtube_id: CqlVuoYIgEg
---

[Part 1: Basic markdown with gem redcarpet]({% post_url 2021-06-10-markdown %}){:target="blank"}

I HAVE READ 10+ BLOGS ON THIS TOPIC. HERE IS THE MOST IDEAL ANSWER BASED ON ALL OF THEM.

Using markdown? With [gem redcarpet](https://github.com/vmg/redcarpet)?

Add [gem rouge](https://github.com/rouge-ruby/rouge) to add **code highlight** your markdown.

## HOWTO

```sh
bundle add redcarpet
bundle add rouge
```

application_helper.rb

```ruby
  require 'redcarpet'
  require 'rouge'
  require 'rouge/plugins/redcarpet'

  class HTML < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  def markdown(text)
    return '' if text.nil?

    options = {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { rel: 'nofollow', target: '_blank' },
      prettify: true
    }

    extensions = {
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      lax_spacing: true,
      no_intra_emphasis: true,
      strikethrough: true,
      superscript: true,
      disable_indented_code_blocks: true,
    }

    # Redcarpet::Markdown.new(HTML.new(options), extensions).render(text).html_safe
    # these 3 lines do same as above 1 line
    renderer = HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)
    markdown.render(text).html_safe
  end
```

Create `rouge.css.erb` and use one of [10+ available themes](https://github.com/rouge-ruby/rouge/tree/master/lib/rouge/themes).

Here are my famorite ones:

```ruby
# app/assets/stylesheets/rouge.css.erb
<%= Rouge::Themes::Base16.mode(:light).render(scope: '.highlight') %>
<%#= Rouge::Themes::ThankfulEyes.render %>
<%#= Rouge::Themes::Base16.mode(:dark).render %>
```

* import the Rouge file into your assets
* add some custom styling if you like

```ruby
# app/assets/stylesheets/application.css
@import "rouge";

# style ```code block```
pre.highlight {
  padding: 10px;
}
# style `code`
code.prettyprint {
  color: red;
  background-color: #F2F2F2;
}
```

## Bonus: download and edit a default Rouge theme


```sh
# console
rougify style github > app/assets/stylesheets/github.css
```

app/assets/stylesheets/application.scss

```ruby
@import "github";
```
