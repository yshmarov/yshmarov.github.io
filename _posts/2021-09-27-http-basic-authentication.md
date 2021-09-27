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

credentials.yml
```ruby
http_auth:
	login: superails
	pass: 123abc
```