---
layout: post
title: "Tracking Online Users using Timestamps"
author: Yaroslav Shmarov
tags: ruby rails
thumbnail: /assets/thumbnails/users-online-symbol.png
---

First, whenever the `current_user` does any action, his `updated_at` will be set to `Time.now`:

```ruby
# app/controllers/application_controller.rb
after_action :update_user_online, if: :user_signed_in?

private

def update_user_online
  current_user.try :touch
end
```

Next, we will just say that the `user` is `online` if he was `updated_at` within the last `2.minutes`:

```ruby
# app/models/user.rb
def online?
  updated_at > 2.minutes.ago
end
```

Now we can get `true` or `false` if we make a call like `@user.online?`:

```ruby
# app/views/users/show.html.erb
<%= @user.online? %>
```

Problems with this approach:
- you do not want to override the purpose of `update_at`
- you WRITE to the database after each request = expensive

### Better approach

Add a separate attribute to the User model:

```ruby
# terminal
rails g migration add_last_online_at_to_users last_online_at:datetime
```

"Throttle" writes to the database: do not write `last_online_at` to the database more than once in 5 minutes:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  after_action :update_user_online, if: :user_signed_in?

  private

  def update_user_online
    return if session[:last_online_at] && session[:last_online_at] > 5.minutes.ago

    current_user.update!(last_online_at: Time.current)
    session[:last_online_at] = Time.current
  end
end
```

That's much better!
