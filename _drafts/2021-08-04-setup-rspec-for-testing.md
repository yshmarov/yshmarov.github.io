---
layout: post
title: "Rspec basic setup"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails rspec code-quality
thumbnail: /assets/thumbnails/rubocop.png
---

Rails new with a testing suite.

### The theory:

Testing tools:
* `rspec`-rails - test framework
* `factory_bot_rails` - generate massives of fake data
* `capybara` - tool for writing tests that interact with the browser and simulate clicks and keystrokes.
* `webdrivers` - for capybara to work with an imaginary browser
* `faker` - fake data samples

Test types (defined by the testing framework):
* `system` - imitating a user flow (Capybara)
* `request` / controller - expect change after a controller action
* `mailer` - expect mail From/To/CC/BCC/Subject/Attachments/Text to be as expected
* `model` - ...
* & more...

Test Driven Development (TDD) - first write failing tests for a feature, than add the feature and make the tests pass.

When to add tests?
* First, create a playground with some basic tests
* Next, write tests for functionality you add

****
rails new my_project -T -d postgresql -m https://raw.githubusercontent.com/jasonswett/testing_application_template/master/application_template.rb
****

Gemfile
```
gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'capybara'
  gem 'webdrivers'
  gem 'faker'
end

initializer 'generators.rb', <<-CODE
  Rails.application.config.generators do |g|
    g.test_framework :rspec,
      fixtures:         false,
      view_specs:       false,
      helper_specs:     false,
      routing_specs:    false,
      request_specs:    false,
      controller_specs: false
  end
CODE

after_bundle do
  generate 'rspec:install'
end
```


rails g rspec:install

devise tests?
```
  gem "database_cleaner"
  gem "launchy"
  gem "selenium-webdriver"
  gem 'fuubar', require: false
  gem 'simplecov', require: false
  gem 'database_cleaner'
```

****

`SIMPLECOV` - spec/spec_helper.rb - on top
```
require 'simplecov'
SimpleCov.minimum_coverage 89.5
SimpleCov.start
```

****

bundle install
rake db:create:all

--format documentation
--format Fuubar
--color

    require 'simplecov'
    require 'faker'
    SimpleCov.start