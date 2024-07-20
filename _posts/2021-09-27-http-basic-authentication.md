---
layout: post
title: "HTTP Basic authentication"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails http-authentication
thumbnail: /assets/thumbnails/lock.png
youtube_id: N7HZ-4zGNe4
---

![http-authentication-example](assets/images/http-basic-auth-example.png)

You can use HTTP basic authentication to restrict access to different controllers/actions.

The easiest way is to use a `http_basic_authenticate_with` callback in a controller:

```diff
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
+  http_basic_authenticate_with name: 'superails', password: '123456', except: :index
```

A better approach where you have more control is to use `authenticate_or_request_with_http_basic(realm = "Application", message = nil, &login_procedure)`, because it allows you to pass multple options and a block.

* `realm` - "scope". You can have different http authentication for different parts of your app. Defaults to `"Application"`.
* `message` - failure message. Default: `*"HTTP Digest: Access denied."`

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :http_authenticate, only: %i[show]

  def index
    @posts = Post.all
  end

  def show
  end

  private

  def http_authenticate
    # conditionally enable the feature only in production:
    # return true if %w(test staging).include? Rails.env
    # return true unless Rails.env == 'production'

    authenticate_or_request_with_http_basic do |username, password|
      username == 'superails' && password == '123456' 
      # better to hide password in credentials:
      username == Rails.application.credentials.dig(:http_auth, :username) && 
        password == Rails.application.credentials.dig(:http_auth, :password)
    end
  end
end
```

```ruby
# credentials.yml
http_auth:
	username: superails
	password: 123456
```

* Check (in a view) if current page required authorization to open:

```ruby
request.headers[:HTTP_AUTHORIZATION].present?
request.authorization.present?
```

### Sustainable ways to include http auth im multiple controllers:

1. **Controller inheritance:**

You can create a controller that will require authentication, and than inherit further controllers from it:

```ruby
# app/controllers/secured_controller.rb
class SecuredController < ApplicationController
  before_action :http_authenticate

  private

  def http_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == 'superails' && password == '123456'
    end
  end
end
```

```diff
# app/controllers/posts_controller.rb
-class PostsController < ApplicationController
+class PostsController < SecuredController
```

```diff
# app/controllers/posts_controller.rb
-class TasksController < ApplicationController
+class TasksController < SecuredController
```

2. **Concern inclusion:**

```ruby
# app/controllers/concerns/http_auth_concern.rb
module HttpAuthConcern  
  extend ActiveSupport::Concern

  included do
    before_action :http_authenticate
  end

  def http_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == 'superails' && password == '123456'
    end
  end
end
```

```diff
# app/controllers/application_controller.rb
class PostsController < ApplicationController
+  include HttpAuthConcern
```

```diff
# app/controllers/posts_controller.rb
class TasksController < ApplicationController
+  include HttpAuthConcern
```

### 3. Bypass authentication by providing username and password in url

As mentioned [here](https://serverfault.com/a/371918), you can append username and password in an URL like `http://username:password@example.com/` to auto-sign in.

Here's how you can do it in a Rails app:

```ruby
class HomeController < ApplicationController
  NAME = 'superails'
  PASSWORD = '12345678'

  http_basic_authenticate_with name: NAME, password: PASSWORD, only: :dashboard

  def landing_page
  end

  def dashboard
  end

  def pricing
  end

  private

  # "http://localhost:3000/home/dashboard"
  # http://NAME:PASSWORD@localhost:3000/home/dashboard/

  # add_http_basic_auth(home_dashboard_path) => http://superails:12345678@localhost:3000/home/dashboard/
  def add_http_basic_auth(url)
    uri = URI.parse(url)
    uri.userinfo = "#{NAME}:#{PASSWORD}"
    uri.to_s
  end
end
```

### Sources:
* [MDN: Basic Authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization#basic_authentication)
* [api.rubyonrails/HttpAuthentication example](https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic.html)
* [api.rubyonrails/HttpAuthentication methods](https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic/ControllerMethods.html)
* [Rails source code](https://github.com/rails/rails/blob/25b14b4d3238d5474c60826ee1b359537af987ef/actionpack/lib/action_controller/metal/http_authentication.rb#L70)
* [apidock/authenticate_or_request_with_http_basic](https://apidock.com/rails/ActionController/HttpAuthentication/Basic/ControllerMethods/authenticate_or_request_with_http_basic)
