---
layout: post
title:  Add custom error pages in a Rails app
author: Yaroslav Shmarov
tags: ruby-on-rails, error-pages, 404
thumbnail: /assets/thumbnails/404.png
---

Series:
1. [Add custom error pages in a Rails app]({% post_url 2023-03-14-style-default-error-pages %})
2. [Style default error pages in a Rails app inside /public folder]({% post_url 2023-03-14-style-default-error-pages %})
3. [DRY custom error pages]({% post_url 2023-07-19-dry-custom-error-pages %})

It is often easy to distinguish a Rails app by going to `/404` or `/500`. You know this screen, right?

![rails-default-error-page](/assets/images/rails-default-error-page.png)

When you create a new rails app, error pages like `404` and `500` are automatically created and kept in `public` folder.

At some point of time, you will what to integrate these pages into your app and style them, like I did here:

![styled-error-page](/assets/images/styled-error-page.png)

Here's how you can integrate the error pages into your app:

```shell
# terminal
rails g controller errors not_found internal_server_error --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework
rm public/{404,500}.html
echo > app/views/layouts/errors.html.erb
```

```ruby
# app/config/application.rb
config.exceptions_app = self.routes
```

```ruby
# app/config/routes.rb
match "/404", via: :all, to: "errors#not_found"
match "/500", via: :all, to: "errors#internal_server_error"
```

```ruby
# app/views/controllers/errors_controller.rb
class ErrorsController < ActionController::Base

  def not_found
    render status: 404
  end

  def internal_server_error
    render status: 500
  end
end
```

```html
<!-- app/views/layouts/errors.html.erb -->
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

```html
<!-- app/views/errors/internal_server_error.html.erb -->
<div class="text-center">
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
</div>
```

```html
<!-- app/views/errors/not_found.html.erb -->
<div class="text-center">
  <br>
  <h2>
    <%= response.status %>
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
</div>
```

### Tailwind example

```html
<!-- app/views/layouts/errors.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>CustomErrorPages</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>

    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <main class="grid h-screen place-items-center">
      <%= yield %>
    </main>
  </body>
</html>
```

```html
<!-- app/views/errors/not_found.html.erb -->
<div class='text-center'>
  <h1 class="font-bold text-4xl"><%= action_name.humanize %></h1>
  <p>This page does not exist</p>
  <%= link_to 'Return to homepage', root_url, class: 'text-blue-500' %>
  <%= image_tag "#{response.status}.png" %>
</div>
```

[More detailed article on the topic](http://www.hoxton-digital.com/posts/dynamic-404-422-amp-500-error-pages-with-rails-internationalization-i18n){:target="blank"}
