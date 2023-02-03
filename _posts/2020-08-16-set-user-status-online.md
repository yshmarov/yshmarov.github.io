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
