---
layout: post
title: Build a Public-facing Rails API with Bearer token authentication 
author: Yaroslav Shmarov
tags: ruby-on-rails rails-api bearer
thumbnail: /assets/thumbnails/api.png
---

Let's say you've got a Rails app, and you want to allow other apps read/write data to your app.

### 1. Build a public API

Start with building an url path:

```ruby
# config/routes.rb
  namespace :api do
    namespace :v1 do
      defaults format: :json do
        get "home/index", to: "home#index" # /api/v1/home/index
      end
    end
  end
```

Controller to handle the url and provide a basic text responce:

```ruby
# app/controllers/api/v1/home_controller.rb
class Api::V1::HomeController < ActionController::Base
  def index
    render json: { message: "Welcome to the app!" }
  end
end
```

Try starting `rails s` in one terminal tab, and doing a CURL request in another tab:

```s
curl -X GET "http://localhost:3000/api/v1/home/index"
# or
curl -X 'GET' \
  'http://localhost:3000/api/v1/home/index' \
  -H 'accept: application/json'
```

Great! You've just made a request and received a JSON responce.

### 2. Allow users to generate API tokens

Prerequisites:
* have a `User` model
* set up [Active Record Encryption]({% post_url 2023-03-19-encrypted-credentials %}) (to encrypt the generated tokens)

```shell
rails g model api_tokens user:references active:boolean token:text
```

When a User creates an ApiToken record, generate and encrypt a token:

```ruby
# app/models/api_token.rb
class ApiToken < ApplicationRecord
  belongs_to :user
  # before_create :generate_token
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  encrypts :token, deterministic: true

  private

  def generate_token
    self.token = Digest::MD5.hexdigest(SecureRandom.hex)
    # self.active = true
  end
end
```

Create a token in the console:

```ruby
current_user = User.first
token = current_user.api_tokens.create!
```

Building the frontend for this must be quite straightforward. 

### 3. Authenticate a user by an API token

We've got an API and we've got tokens. Now, let's allow only requests that have a valid API token in the header access our API.

A Basic usecase example would be allowing a user to access only his own posts.

A CURL GET request with a Bearer Authorization header with token `mySecretToken` could look like this:

```s
curl -X GET "http://localhost:3000/api/v1/home/index" -H "Authorization: Bearer mySecretToken"
curl -X GET "http://localhost:3000/api/v1/posts/1" -H "Authorization: Bearer mySecretToken"
curl -X GET "http://localhost:3000/api/v1/posts" -H "Authorization: Bearer mySecretToken"
```

Create a `BaseController`. API controllers that require authentication should inherit from it. Require authentication to perform API requests with a valid active API token and find the `current_user` (owner of the token):

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  before_action :authenticate

  attr_reader :current_user, :current_api_token

  private

  def authenticate
    authenticate_user_with_token || handle_bad_authentication
  end

  def authenticate_user_with_token
    authenticate_with_http_token do |token, options|
      @current_api_token = ApiToken.where(active: true).find_by_token(token)
      @current_user = @current_api_token&.user
    end
  end

  def handle_bad_authentication
    render json: { message: "Bad credentials" }, status: :unauthorized
  end

  def handle_not_found
    render json: { message: "Record not found" }, status: :not_found
  end
end
```

Inherit from the `BaseController`:

```diff
# app/controllers/api/v1/home_controller.rb
-class Api::V1::HomeController < ActionController::Base
+class Api::V1::HomeController < Api::V1::BaseController
  def index
-    render json: { message: "Welcome to the app!" }
+    render json: {
+      current_api_token_id: current_api_token.id,
+      current_user_id: current_user.id
+    }
  end
end
```

Now, if somebody tries to make an API request without a valid API token, he will get the *"Bad credentials"* message.

### 4. Testing

```ruby
# test/integration/api_welcome_page_test.rb
require 'test_helper'

class ApiWelcomePageTest < ActionDispatch::IntegrationTest
  test 'when auth token is invalid' do
    get api_v1_welcome_path, headers: { HTTP_AUTHORIZATION: 'Token token=123' }
    assert_includes request.headers['HTTP_AUTHORIZATION'], '123'
    assert_response :unauthorized
    assert_includes response.body, 'Bad credentials'
  end

  test 'with valid auth token' do
    user = User.create!
    api_token = user.api_tokens.create!
    raw_token = api_token.raw_token
    get api_v1_welcome_path, headers: { HTTP_AUTHORIZATION: "Token token=#{raw_token}" }
    assert_response :success
    assert_includes response.body, 'Welcome to the SupeRails API!'
  end
end
```

That's it!
