---
layout: post
title: "User status online: TLDR"
author: Yaroslav Shmarov
tags: 
- ruby on rails
- tutorial
- premium
- subscription
- saas
- mvp
- startup
thumbnail: https://ps.w.org/cbxuseronline/assets/icon-256x256.png?rev=2284897
---

* Whenever the `current_user` does any action, his `updated_at` will be set as `Time.now`.

application_controller.rb

```
after_action :user_activity, if: :user_signed_in?

private

def user_activity
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
