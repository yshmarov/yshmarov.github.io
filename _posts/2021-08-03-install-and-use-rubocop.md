---
layout: post
title: "Install and use Rubocop - TLDR"
author: Yaroslav Shmarov
tags: ruby rails rubyonrails rubocop code-quality
thumbnail: /assets/thumbnails/rubocop.png
---

[Rubocop](https://github.com/rubocop/rubocop-rails) is one of the most essential gems that I always add to all my apps.

Rails 8 [will have Rubocop](https://github.com/rails/rubocop-rails-omakase/blob/main/rubocop.yml) included by default.

[Official docs](https://docs.rubocop.org/rubocop-rails/index.html)

### 1. Installation

```ruby
# Gemfile
group :development, :test do
  gem 'rubocop-rails', require: false
end
```

Create a config file:

```shell
# console
bundle
echo > .rubocop.yml
```

My basic setup:

```yml
# .rubocop.yml - basic setup example
require: 
  - rubocop-rails

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3.0
  Exclude:
    - vendor/bundle/**/*
    - '**/db/schema.rb'
    - '**/db/**/*'
    - 'config/**/*'
    - 'bin/*'
    - 'config.ru'
    - 'Rakefile'

Style/Documentation:
  Enabled: false

Style/ClassAndModuleChildren:
  Enabled: false

Rails/Output:
  Enabled: false

Style/EmptyMethod:
  Enabled: false

Bundler/OrderedGems:
  Enabled: false
  
Lint/UnusedMethodArgument:
  Enabled: false

Style/FrozenStringLiteralComment:
  Enabled: false
```

### 2. Run the cops

```shell
# console - run check:
bundle exec rubocop
# console - run check on specific file/folder:
rubocop app/models/user.rb
```

### 3. Disable cops

1. Disable in a file, around a code block:

app/models/user.rb

```ruby
  # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
  def full_name
    ...
  end
  # rubocop: enable Metrics/AbcSize, Metrics/MethodLength
```  

2. Disable on a whole file:

```yml
# .rubocop.yml
Metrics/ClassLength:
  Exclude:
    - 'app/models/user.rb'
    - 'app/controllers/users_controller.rb'
```

### 4. AutoCorrect

```shell
# console - safe auto correct
rubocop -a

# console - dangerous auto correct
rubocop - A

# console - autocorrect a single specific cop
bundle exec rubocop -a --only Style/FrozenStringLiteralComment
bundle exec rubocop -A --only Layout/EmptyLineAfterMagicComment

# generate comments for uncorrected problems and stop flagging them as TODO:
rubocop --auto-correct --disable-uncorrectable
```

### 5. Github workflows

```yml
# mkdir .github
# mkdir .github/workflows
# echo > .github/workflows/.lint.yml
name: Code style

on: [pull_request]

jobs:
  lint:
    name: all linters
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: rubocop
        run: bundle exec rubocop --parallel
      # - name: erb-lint
      #   run: bundle exec erblint --lint-all
```

That's it!
