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

## Installation

Gemfile

```ruby
group :development, :test do
  gem 'rubocop-rails', require: false
end
```

console

```
bundle
echo > .rubocop.yml
```

.rubocop.yml - basic setup example

```
require: 
  - rubocop-rails

AllCops:
  TargetRubyVersion: 3.0.1
  Exclude:
    - '**/db/schema.rb'
    - '**/db/**/*'
    - 'config/**/*'
    - 'bin/*'

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
```

## Run the cops

console - run check:

```
bundle exec rubocop
```

console - run check on specific file/folder:

```
rubocop app/models/user.rb
```

## Disable cops

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

.rubocop.yml

```
Metrics/ClassLength:
  Exclude:
    - 'app/models/user.rb'
    - 'app/controllers/users_controller.rb'
```


## AutoCorrect

console - safe auto correct

```
rubocop -a
```

console - dangerous auto correct

```
rubocop - A
```

console - autocorrect a single specific cop

```
bundle exec rubocop -a --only Style/FrozenStringLiteralComment
bundle exec rubocop -A --only Layout/EmptyLineAfterMagicComment
```

generate comments for uncorrected problems and stop flagging them as TODO:

```
rubocop --auto-correct --disable-uncorrectable
```
