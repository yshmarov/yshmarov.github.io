---
layout: post
title: "Install and use Rubocop - TLDR"
author: Yaroslav Shmarov
tags: ruby rails rubyonrails rubocop code-quality
thumbnail: /assets/thumbnails/rubocop.png
---

Resources:
* [https://docs.rubocop.org/rubocop-rails/index.html](https://docs.rubocop.org/rubocop-rails/index.html){:target="blank"}
* [https://github.com/rubocop/rubocop-rails](https://github.com/rubocop/rubocop-rails){:target="blank"}

### 1. Installation

```ruby
# Gemfile
group :development, :test do
  gem 'rubocop-rails', require: false
end
```

```shell
# console
bundle
echo > .rubocop.yml
```

```yml
# .rubocop.yml - basic setup example
require: 
  - rubocop-rails

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.1.2
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

1. in a file, for a method:

app/models/user.rb

```ruby
  # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
  def full_name
    ...
  end
  # rubocop: enable Metrics/AbcSize, Metrics/MethodLength
```  

2. on a whole file:

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

### 5. Github workflow

```yml
# mkdir .github
# mkdir .github/workflow
# echo > .github/workflow/.lint.yml
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
