---
layout: post
title: "Install and use Rubocop - TLDR"
author: Yaroslav Shmarov
tags: ruby rails rubyonrails rubocop
thumbnail: /assets/thumbnails/rubocop.png
---

Resources:
* [https://docs.rubocop.org/rubocop-rails/index.html](https://docs.rubocop.org/rubocop-rails/index.html){:target="blank"}
* [https://github.com/rubocop/rubocop-rails](https://github.com/rubocop/rubocop-rails){:target="blank"}

## Installation

Gemfile
```
gem 'rubocop-rails', require: false
```
console
```
bundle
echo > .rubocop.yml
```
.rubocop.yml
```
require: 
  rubocop-rails
```

## Commands

console - run check
```
rubocop --require rubocop-rails
```
console - run check on specific file/folder:
```
rubocop app spec app/models/user.rb
```

## Disable check on code snipped

user.rb
```
  # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
  def full_name
    ...
  end
  # rubocop: enable Metrics/AbcSize, Metrics/MethodLength
```  

## AutoCorrect

console - safe auto correct
```
rubocop -a
# or
rubocop --auto-correct
```
console - dangerous auto correct
```
rubocop - A
# or
rubocop --auto-correct-all
```

generate comments for uncorrected problems and stop flagging them as TODO:
```
rubocop --auto-correct --disable-uncorrectable
```

## Advanced Setup

`.rubocop.yml` - PRO configuration example:

```
require:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  TargetRubyVersion: 2.6.5
  Exclude:
    - 'vendor/**/*'
    - '**/db/schema.rb'
    - '**/node_modules/**/*'
    - '**/db/**/*' # FIXME: go back through and fix up errors
    - 'bin/*'

Metrics/BlockLength:
  ExcludedMethods:
    - describe
    - context
    - aasm
    - configure
    - before
    - setup
    - draw
    - resources
    - define
    - included
  Exclude:
    - '**/lib/tasks/**/*'
    - '**/spec/**/*'
    - '**/db/migrate/*'

Metrics/MethodLength:
  CountAsOne: ['array', 'heredoc', 'hash']
  Exclude:
    - 'app/decorators/user_decorator.rb'
    - '**/db/migrate/**/*'

Metrics/ClassLength:
  Exclude:
    - 'app/decorators/user_decorator.rb'

Metrics/AbcSize:
  Exclude:
    - 'app/decorators/user_decorator.rb'
    - 'app/helpers/welcome_helper.rb'
    - 'app/controllers/welcome_controller.rb'

Metrics/LineLength:
  IgnoredPatterns: ['(\A|\s)#']
  Exclude:
    - '**/db/**/*'

Rails/UnknownEnv:
  Environments:
    - production
    - uat
    - review
    - test
    - development

Rails/HasAndBelongsToMany:
  Enabled: false

Layout/EmptyLineAfterMagicComment:
  Exclude:
    - 'app/models/**/*'
    - 'spec/factories/*'
    - 'spec/models/*'
    - 'app/serializers/*'

RSpec/ExampleLength:
  Enabled: false

RSpec/MultipleExpectations:
  Enabled: false

RSpec/MultipleMemoizedHelpers:
  Enabled: false

RSpec/NestedGroups:
  Enabled: false

Style/TrailingCommaInArguments:
  Enabled: false

Rails/HelperInstanceVariable:
  Enabled: false

Performance/RegexpMatch:
  Enabled: false
```


