---
layout: post
title: "Markdown Level 2. Style markdown css with gem Rouge"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails markdown redcarpet rouge
thumbnail: /assets/thumbnails/markdown.png
---

I HAVE READ 10+ BLOGS ON THIS TOPIC. HERE IS THE MOST IDEAL ANSWER BASED ON ALL OF THEM.

Using markdown? With [gem redcarpet](https://github.com/vmg/redcarpet)?

Add [gem rouge](https://github.com/rouge-ruby/rouge) to add some styling to your markdown.

## HOWTO

Gemfile

```ruby
gem "redcarpet"
gem 'rouge'
```

application_helper.rb

```ruby
  require 'redcarpet'
  require 'rouge'
  require 'rouge/plugins/redcarpet'

  class HTML < Redcarpet::Render::HTML
   def initialize(extensions = {})
     super extensions.merge(link_attributes: { target: '_blank' })
   end
    include Rouge::Plugins::Redcarpet
  end

  def markdown(text)
    options = {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { rel: 'nofollow' },
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

app/assets/stylesheets/rouge.scss.erb - add one of [10+ available themes](https://github.com/rouge-ruby/rouge/tree/master/lib/rouge/themes)

```ruby
<%= Rouge::Themes::Base16.mode(:light).render(scope: '.highlight') %>
<%= Rouge::Themes::ThankfulEyes.render %>
<%= Rouge::Themes::Base16.mode(:dark).render %>
```

app/assets/stylesheets/application.scss

```ruby
@import "rouge";
```

****

## Bonus 1 - override the theme

app/assets/stylesheets/rouge.scss.erb

```ruby
<%= Rouge::Themes::Base16.mode(:dark).render %>

div.highlight {
  border-radius: 5px;
  padding: 10px;
  padding-bottom: 0px;
  margin-bottom: 12px;
}
pre.highlight {
  padding-bottom: 10px;
}
```

## Bonus 2 - download and edit a default Rouge theme

console

```
rougify style github > app/assets/stylesheets/github.css
```

app/assets/stylesheets/application.scss

```ruby
@import "github";
```
