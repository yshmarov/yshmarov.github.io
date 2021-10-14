---
layout: post
title: "5 ways to associate current_user with record on create"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails users associations
thumbnail: /assets/thumbnails/devise.png
---

### #1 Add to params

```ruby
def create
  @inbox = Inbox.new(inbox_params)
  @inbox.user = current_user
end
```

### #2 Relationship

```ruby
def create
  @inbox = current_user.inboxes.new(post_params)
end
```

### #3 Merge in params

```ruby
def create
  @inbox = Inbox.new(inbox_params.merge({ user: current_user }))
end
```

### #4 Merge in private params

```ruby
def create
  @inbox = Inbox.new(inbox_params)
  @inbox.user = current_user
end

def inbox_params
  params.require(:inbox).permit(:name).merge(user: current_user)
end
```

### #5 Add current_user by default in model association

[Here's how you can set current_user in the model]({% post_url 2021-10-07-current-attribute-for-user-per-request %})
