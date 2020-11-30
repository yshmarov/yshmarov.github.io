---
layout: post
title: "See if User is online: TLDR"
author: Yaroslav Shmarov
tags: 
- ruby on rails
- tutorial
- premium
- subscription
- saas
- mvp
- startup
thumbnail: https://upload.wikimedia.org/wikipedia/commons/9/9a/Green_circle.png
---

* Whenever the `current_user` does any action, his `updated_at` will be set as `Time.now`.

application_controller.rb

```
after_action :update_user_online, if: :user_signed_in?

private

def update_user_online
  current_user.try :touch
end
```

* And we will just say that the `user` is `online` if he was `updated_at` during the last `2.minutes` 

user.rb

```
def online?
  updated_at > 2.minutes.ago
end
```

* Now we can get `true` or `false` if we make a call like `@user.online?`

users/show.html.erb

```
<%= @user.online? %>
```
