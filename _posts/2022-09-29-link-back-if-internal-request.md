---
layout: post
title: "Link to previous page if internal request"
author: Yaroslav Shmarov
tags: rails ruby-on-rails
thumbnail: /assets/thumbnails/rails-logo.png
---

Sometimes you would like to let the user navigate to a previous page in history.

However, you don't want to let the user navigate to a previous url that is **from another website**.

Here's how I prevent 

Determine if the URL is from the current website:

```ruby
def internal_request?
  previous_url = request.referrer
  return false if previous_url.blank?

  referrer = URI.parse(previous_url)

  return true if referrer.host == request.host

  false
end
```

Hide link "Back" if the request is not from current website:

```ruby
if internal_request?
  # link_to 'Back', 'javascript:history.back()'
  link_to 'Back', request.referrer
end
```

That's it!
