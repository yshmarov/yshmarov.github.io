---
layout: post
title:  DRY custom error pages
author: Yaroslav Shmarov
tags: ruby-on-rails, error-pages, 404
thumbnail: /assets/thumbnails/404.png
youtube_id: moeJ_0WQZxo
---

Series:
1. [Add custom error pages in a Rails app]({% post_url 2020-12-14-custom-error-pages %})
2. [Style default error pages in a Rails app inside /public folder]({% post_url 2023-03-14-style-default-error-pages %})
3. [**DRY custom error pages**]({% post_url 2023-07-19-dry-custom-error-pages %})

Approach #2 stays my favorite one, because it is the least intrusive (lowest quantity of files to change and maintain).

**This** is an improvement of approach #1, where we add our error pages to our routes.

First, say that you want to handle errors via your routes:

```ruby
# config/application.rb
config.exceptions_app = self.routes
```

Add error paths to routes:

```ruby
# config/routes.rb
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
```

Controller to handle all errors:

```ruby
# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  def not_found
    render status: :not_found,
           template: 'errors/index'
  end

  def internal_server_error
    render status: :internal_server_error,
           template: 'errors/index'
  end

  def unprocessable_entity
    render status: :unprocessable_entity,
           template: 'errors/index'
  end
end
```

Error layout file that accepts **TailwindCSS**:

```html
<!-- app/views/layouts/errors.html.erb -->
<!DOCTYPE html>
<html class="h-full antialiased">
  <head>
    <%= render 'shared/meta_tags' %>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag 'tailwind', 'inter-font', 'data-turbo-track': 'reload' %>
    <%= stylesheet_link_tag 'application', 'data-turbo-track': 'reload' %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="font-sans font-normal leading-normal bg-sky-950 text-gray-200 flex flex-col min-h-screen">
    <main class="grid h-screen place-items-center">
      <%= yield %>
    </main>
  </body>
</html>
```

One generic template file that is populated by text from an i18n file:

```html
<!-- app/views/errors/index.html.erb -->
<div class='text-center'>
  <h1 class="font-bold text-4xl">
    <%= response.status %>
    <%= action_name.humanize %>
  </h1>
  <p>
    <%= t :message, scope: [:errors, action_name] %>
  </p>
  <%= link_to 'Return to homepage', root_url, class: 'text-blue-500' %>
  <%= image_tag 'errors.png' %>
</div>
```

I18n file that handles different text based on error message:

```yml
# config/locales/en.yml
en:
  errors:
    internal_server_error:
      message: It's not you. Something went wrong on our end.
    not_found:
      message: Sorry, we couldn't find that page.
    unprocessable_entity:
      message: Sorry, we couldn't process that request.
```

That's it! 🤠
