---
layout: post
title: "Use SwearJar to moderate and censor bad words. **** you!"
author: Yaroslav Shmarov
tags: ruby-on-rails profanity moderation
thumbnail: /assets/thumbnails/profanity.png
---

An easy way to find and censor profanity (bad words) is to use the gem [swearjar](https://github.com/joshbuddy/swearjar){:target="blank"}

```shell
# terminal
bundle add swearjar
```

```ruby
# app/models/message.rb
  def moderated_body
    Swearjar.default.censor(body)
  end
```

```diff
# app/views/messages/_message.html.erb
-<%= message.body %>
+<%= message.moderated_body %>
```

Result:

![swearjar-profanity-filter](/assets/images/swearjar-profanity-filter.png)

That's it!
