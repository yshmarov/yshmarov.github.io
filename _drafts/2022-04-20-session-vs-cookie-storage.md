---
layout: post
title: "Leveraging Session and Cookie storage"
author: Yaroslav Shmarov
tags: rails session cookies
thumbnail: /assets/thumbnails/turbo.png
---

`gem activerecord-session-store`???

[Ruby on Rails: Dark Mode: TLDR]({% post_url 2020-09-21-ruby-on-rails-dark-mode %}){:target="blank"}

You can store information

Not logged in users

Before user has to log in, store in session/cookies.

When the user logs in, transfer info stored in session/cookies to database and tie to to the `current_user`.


https://api.rubyonrails.org/classes/ActionDispatch/Cookies.html
https://api.rubyonrails.org/classes/ActionDispatch/Session.html
Session VS Cookie storage
Session - stored on **the server**
Cookie - stored on **local machine**


```ruby
<%= button_to "toggle", toggle_view_path %>
<b style="color:green"><%= notice %></b>
<b style="color:red"><%= session[:view_layout] %></b>
```

```ruby
post :toggle_view, to: 'posts#toggle_view'
```

```ruby
def toggle_view
  session[:view_layout] = if session[:view_layout] == true
                            nil
                          else
                            true
                          end
  redirect_to posts_path, notice: session[:view_layout]
end
```

```ruby
class ApplicationController < ActionController::Base
  before_action :set_user_from_session

  protected

  def set_user_from_session
    @user_id = session.id.to_s
    @my_orders = Order.where(session_uid: @user_id)
    @current_order = @my_orders.draft.first
  end
end
```

```ruby
session[:table_delivery] = params[:table_delivery]
session[:table_delivery] = nil
```