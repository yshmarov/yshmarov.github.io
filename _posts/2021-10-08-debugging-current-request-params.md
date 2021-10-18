---
layout: post
title: "Tiny Tip: Debugging current request"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails devise
thumbnail: /assets/thumbnails/ladybug.png
---

![rails-debug-request-params](/assets/images/rails-debug-request-params.png)

* Trying to understand how a legacy app is set up?
* Don't know what you are looking at?

Try inspecting all the requests by adding `params.to_yaml` or `params.inspect` or `debug(params)` or `params.to_unsafe_h` to your layout file:

#app/views/layouts/application.html.erb
```
  <body>
    <%= params.to_yaml %>
    <%= params.inspect %>
    <%= debug(params) %>
    <%= params.to_unsafe_h %>
    <hr>
    <%= yield %>
  </body>
```

For example, `<%= params.inspect %>` will give you

```
 #<ActionController::Parameters {"controller"=>"inboxes", "action"=>"edit", "id"=>"4"} permitted: false> 
```

`<%= params.to_unsafe_h %>` will give you

```ruby
 {"controller"=>"inboxes", "action"=>"edit", "id"=>"4"} 
```

`<%= debug(params) %>` will give you (BEST)

```
 #<ActionController::Parameters {"controller"=>"inboxes", "action"=>"edit", "id"=>"4"} permitted: false> 
```

Source: [Debugging Rails Applications](https://edgeguides.rubyonrails.org/debugging_rails_applications.html)
