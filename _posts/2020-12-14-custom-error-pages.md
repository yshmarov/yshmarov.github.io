---
layout: post
title:  Add custom error pages in a Rails app
author: Yaroslav Shmarov
tags: 
- ruby on rails
- error pages
thumbnail: https://previews.123rf.com/images/arcady31/arcady311011/arcady31101100012/8157731-404-error-sign.jpg
---

When you create a new rails app, error pages like `404` and `500` are automatically created and kept in `public` folder.

At some point of time, you will what to integrate these pages into your app and style them. Here's how you can integrate them into your MVC structure:

console

```
rails g controller errors not_found internal_server_error --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework
rm public/{404,500}.html
echo > app/views/layouts/errors.html.erb
```

application.rb

```
config.exceptions_app = self.routes
```

routes.rb

```
match "/404", via: :all, to: "errors#not_found"
match "/500", via: :all, to: "errors#internal_server_error"
```

errors_controller.rb

```
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!

  def not_found
    render status: 404
  end

  def internal_server_error
    render status: 500
  end
end
```

layouts/errors.html.erb

```
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= Rails.application.class.module_parent_name %></title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
    <%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

internal_server_error.html.erb

```
<center class="container">
  <br>
  <h2>
    500
    <%= action_name.humanize %>
  </h2>
  <hr>
  <b>
    We had a problem loading this page.
  </b>
  <hr>
  <%= link_to "Back", root_path %>
</center>
```

not_found.html.erb

```
<center class="container">
  <br>
  <h2>
    404
    <%= action_name.humanize %>
  </h2>
  <hr>
  <b>
    The page you were looking for doesn't exist.
  </b>
  <br>
  You may have mistyped the address or the page may have moved.
  <hr>
  <%= link_to "Back", root_path %>
</center>
```

[More detailed article on the topic](http://www.hoxton-digital.com/posts/dynamic-404-422-amp-500-error-pages-with-rails-internationalization-i18n){:target="blank"}
