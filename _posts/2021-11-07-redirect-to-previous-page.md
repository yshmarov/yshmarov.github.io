---
layout: post
title: "TIP: URL helper: Redirect to previous page"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails url
thumbnail: /assets/thumbnails/url.png
---

You can use 
```ruby
<%= link_to "return", request.referrer %>
```
to get to the previous page, but it is better to use 
```ruby
<%= link_to "return", :back %>
```
because the `:back` thing provides the [following code logic](https://github.com/rails/rails/blob/main/actionview/lib/action_view/helpers/url_helper.rb#L48){:target="blank"}:
```ruby
request.referrer || "javascript:history.back()"
```

****

```ruby
<%= link_to "return", request.referrer %>
# Will generate an absolute url to origin page.
# If no previous page, will be an url to CURRENT page
```

```ruby
javascript:history.back()
# The javascript leverages in-browser navigation.
# If no previous page, will be link to something like "New tab"
```

* [More about redirecting - in the RoR API docs](https://api.rubyonrails.org/classes/ActionController/Redirecting.html){:target="blank"}
* [Rails 5 improves redirect_to :back method](https://www.bigbinary.com/blog/rails-5-improves-redirect_to_back-with-redirect-back){:target="blank"}
