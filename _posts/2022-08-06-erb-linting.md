---
layout: post
title: "auto-style your html.erb with gem erb-lint"
author: Yaroslav Shmarov
tags: ruby-on-rails erb haml
thumbnail: /assets/thumbnails/html.png
---

`*.html.erb` tends to get ugly and inconsistent.

Luckily, Shopify has created some good static-code-analysis libraries, that scan your ERB or HTML and show/correct style errors.

Think "[Rubocop]({% post_url 2021-08-03-install-and-use-rubocop %}){:target="blank"} for `*.html.erb`":

* [`gem erb-lint`](https://github.com/Shopify/erb-lint){:target="blank"}
* [`gem better-html`](https://github.com/Shopify/better-html){:target="blank"}

At work I use only the `erb-lint` one.

Here's how you can install, configure, and use the `erb-lint` gem:

```ruby
# Gemfile
group :development, :test do
  gem "erb_lint", require: false
end
```

```shell
# console
echo > .erb-lint.yml
```

To run ERB Lint locally, use any one of the following:

```shell
# find issues 
bundle exec erblint --lint-all
# find issues and autocorrect
bundle exec erblint --lint-all --autocorrect
bundle exec erblint -la -a
```

My erb linter looks like this:

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

You can find how to set up Github CI/CD to run the linter in this post:
[Rubocop with Github Actions]({% post_url 2021-08-03-install-and-use-rubocop %}){:target="blank"}
