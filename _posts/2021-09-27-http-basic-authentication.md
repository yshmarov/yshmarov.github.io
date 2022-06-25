---
layout: post
title: "HTTP Basic authentication"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails http-authentication
thumbnail: /assets/thumbnails/lock.png
---

![http-authentication-example](assets/images/http-basic-auth-example.png)

You can use basic HTTP authentication to restrict access to different controller actions without 

```ruby
# app/controllers/inboxes_controller.rb
class InboxesController < ApplicationController
  before_action :authenticate, only: %i[index show]

  def index
    @inboxes = Inbox.all
  end

  def show
  end

  private
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      # either
      username == 'superails' && password == '123abc' 
      # or
      username == Rails.application.credentials.dig(:http_auth, :login) && 
        password == Rails.application.credentials.dig(:http_auth, :pass)
    end
  end
end
```

```ruby
# credentials.yml
http_auth:
	login: superails
	pass: 123abc
```

### Advanced usage:

You can create a controller that will require authentication, and than inherit further controllers from it:

```ruby
# app/controllers/secured_controller.rb
class SecuredController < ApplicationController
  before_action :authenticate

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == 'ewlit' && password == '123456'
    end
  end
end
```

```diff
# app/controllers/inboxes_controller.rb
-class InboxesController < ApplicationController
+class InboxesController < SecuredController
```

```diff
# app/controllers/inboxes_controller.rb
-class TasksController < ApplicationController
+class TasksController < SecuredController
```

Sources:
* [apidock/authenticate_or_request_with_http_basic](https://apidock.com/rails/ActionController/HttpAuthentication/Basic/ControllerMethods/authenticate_or_request_with_http_basic)
* [api.rubyonrails/HttpAuthentication](https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic/ControllerMethods.html)
