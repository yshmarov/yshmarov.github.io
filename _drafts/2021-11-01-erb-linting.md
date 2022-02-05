---
layout: post
title: "Moving from haml to erb. Gem erb-lint."
author: Yaroslav Shmarov
tags: ruby-on-rails erb haml
thumbnail: /assets/thumbnails/html.png
---

linters
https://docs.decidim.org/en/develop/guide_commands/


https://briansigafoos.com/linters/





**Back 2 erb**

After years of using (and advocating for) `HAML`, I'm switching back to `ERB`.

Why? Not because I like it more.

1. Because it is more popular, thus lowering the entry barrier for people reading my code. (Stupid reason)
2. Because in the new world of StimulusJS & Hotwire Turbo we now have to write a lot of `data` attributes and `dom_id`s, and I want to keep everything consistent. (Better reason)
3. Because I had to get used to using it at work. 

Althrough, haml-like logical nesting will forever be a must-have in my code. And if I had to draft an HTML page right away (without a framework), I would be able to do it faster and more elegantly in HAML. Haml is a viable way to writing beautiful HTML, that can be used way beyond the context of Ruby on Rails.

https://www.reddit.com/r/rails/comments/gs0x4b/htmlerb_vs_htmlhaml_vs_htmlslim_which_one_do_you/

**Converting `haml` to `erb`**

gem haml-rails

**gem erb-lint**

`html.erb` tends to get ugly. 

Luckily, Shopify has created good static-code-analysis libraries, that view your ERB or HTML and show/correct style errors. Think "Rubocop for HTML/ERB":

* [gem better-html](https://github.com/Shopify/better-html),
* [gem erb-lint](https://github.com/Shopify/erb-lint).

At work we use only the `erb-lint` one.

Here's how you can install, configure, and use the `erb-lint` gem:

```ruby
# Gemfile
group :development, :test do
  gem "erb_lint", require: false
end
```

```sh
# console
echo > .erb-lint.yml
```

To run ERB Lint locally, use any one of the following:

# this will automatically fix issues where possible
bundle exec erblint
bundle exec erblint -a
bundle exec erblint --lint-all
bundle exec erblint -a --lint-all
bundle exec erblint --lint-all --autocorrect
bundle exec erblint -la -a


```yaml
# .erb-lint.yml
---
EnableDefaultLinters: false
linters:
  Rubocop:
    enabled: true
    exclude:
      - "**/vendor/**/*"
      - "**/vendor/**/.*"
      - "bin/**"
      - "db/**/*"
      - "spec/**/*"
      - "config/**/*"
      - "node_modules/**/*"
    rubocop_config:
      inherit_from:
        - .rubocop.yml
      Layout/InitialIndentation:
        Enabled: false
      Layout/TrailingEmptyLines:
        Enabled: false
      Layout/TrailingWhitespace:
        Enabled: false
      Naming/FileName:
        Enabled: false
      Style/FrozenStringLiteralComment:
        Enabled: false
      Layout/LineLength:
        Enabled: false
      Lint/UselessAssignment:
        Enabled: false
      Layout/FirstHashElementIndentation:
        Enabled: false
```
