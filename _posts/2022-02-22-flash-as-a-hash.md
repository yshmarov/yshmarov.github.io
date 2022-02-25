---
layout: post
title: "TIL: Pass a Hash to Flash"
author: Yaroslav Shmarov
tags: rails today-i-learned
thumbnail: /assets/thumbnails/rails-logo.png
---

Today I learned:

You are free to pass a HASH to a flash message. Not just a string 😀

```ruby
# app/controllers/posts_controller.rb
flash[:post_status] = "Success. Post created" # a string
flash[:post_status] = { title: "Success", subtitle: "Post created" } # a hash!
```

```ruby
# app/views/shared/_flash.html.erb
<% flash.each do |type, message| %>
  <%= type %>
  <%= message[:title] %>
  <%= message[:subtitle] %>
<% end %>
```

* More about [ActionDispatch::Flash](https://api.rubyonrails.org/classes/ActionDispatch/Flash.html){:target="blank"} (official docs)
* [Dismissable Flash Messages with Hotwire without page refresh]({% post_url 2021-10-29-turbo-hotwire-flash-messages %}){:target="blank"}
