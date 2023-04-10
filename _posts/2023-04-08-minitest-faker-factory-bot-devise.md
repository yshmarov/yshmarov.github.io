---
layout: post
title: Testing Devise authentication with Minitest and Faker
author: Yaroslav Shmarov
tags: ruby rails minitest faker
thumbnail: /assets/thumbnails/ladybug.png
---

When setting up a new Rails app with Devise, you should set up your test suite to work with **authentication** and write **controller** (integration) and **system** tests for the authentication flow.

Here's a reusable approach to doing this!

First, fix the user fixtures to have unique emails:

```ruby
# test/fixtures/users.yml
one:
  email: yaro@superails.com
two:
  email: shm@superails.com
```

Importing devise into your `test_helper` will enable the `sign_in @user` method.

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  ...
  include Devise::Test::IntegrationHelpers
end
```

Controller (integration) test for login (assuming `dashboard` is a page available only for authenticated users):

```ruby
# test/integration/devise_auth_test.rb
require "test_helper"

class DeviseAuthTest < ActionDispatch::IntegrationTest
  test "user can login" do
    get static_dashboard_path
    assert_response :redirect
    assert_redirected_to new_user_session_path

    user = users(:one)
    sign_in user
    get static_dashboard_path
    assert_response :success
  end
end
```

System (browser) tests:

```ruby
# test/system/devise_auth_system_test.rb
require 'application_system_test_case'

class DeviseAuthSystemTest < ApplicationSystemTestCase
  test 'sign in existing user' do
    user = users(:one)
    sign_in user

    visit static_dashboard_path
    assert_current_path static_dashboard_path
    assert_text 'Find me in app/views/static/dashboard.html.erb'
  end

  test 'create user and sign in' do
    User.create(email: @email, password: @password)
    @email = Faker::Internet.email
    @password = Faker::Internet.password(min_length: 10, max_length: 30)

    visit static_dashboard_path
    # visit new_user_session_path

    fill_in 'Email', with: @email
    fill_in 'Password', with: @password
    click_button 'Log in'

    assert_current_path static_dashboard_path
    assert_text 'Signed in successfully.'
  end
end
```

If you don't want to look at the popup browser when running system tests, you can use `headless_chrome`:

```ruby
# test/application_system_test_case.rb
  # driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
```

Commands to run the tests:

```ruby
rails test
rails test:system
rails test:all
```

Reset test database:

```ruby
rake db:drop RAILS_ENV=test
rake db:create RAILS_ENV=test
rake db:migrate RAILS_ENV=test
```

That's it!
