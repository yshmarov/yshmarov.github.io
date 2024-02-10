---
layout: post
title:  "Ruby on Rails: Dark Mode: TLDR"
author: Yaroslav Shmarov
tags: 
- ruby on rails
- dark mode
- dark theme
- bootstrap
- tldr
thumbnail: /assets/thumbnails/dark-mode.png
youtube_id: N2y3AglGKQ4
---

Usually an app can have dark mode based on a users' [device preferences](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme), or if he manually turns it on in your app.

Here's how dark mode works on one of my apps:

![dark-mode](/assets/2020-09-21-ruby-on-rails-dark-mode/dark-mode.gif)

[Live Demo - log in and click yourself!](https://saas.corsego.com/){:target="blank"}

### Here's how you can add dark mode to a Rails app:

By default, our app will inherit users device `prefers-color-scheme`, but we will also let the user manually switch the preference in the app.

**Cookie storage** is the easyest way to store a users theme preferences without unnesesary complications.

First, add links to switch the color theme and allow setting a class on the `<body>` based on the theme set in the cookies.

```diff
# app/views/layouts/application.html.erb
-<body>
+<body class="<%= cookies[:theme] %>">
+  <%= cookies[:theme] %>
+  <%= link_to 'light', set_theme_path(theme: 'light') %>
+  <%= link_to 'dark', set_theme_path(theme: 'dark') %>
+  <%= link_to 'system default', set_theme_path %>
  <%= yield %>
</body>
```

Controller to switch the prefered theme in cookies:

```ruby
# app/controllers/theme_controller.rb
class ThemeController < ApplicationController
  def update
    cookies[:theme] = params[:theme]
    redirect_to(request.referrer || root_path)
  end
end
```

Add route to theme switch:

```ruby
# config/routes.rb
  get 'set_theme', to: 'theme#update'
```

Update your css file to either use device color scheme (`body` styles), or override it with color scheme from cookies (`body.light` and `body.dark` styles):

```css
/* app/assets/stylesheets/application.css */
:root {
  --light-bg-color: silver;
  --light-text-color: white;
  --dark-bg-color: black;
  --dark-text-color: white;
} 

@media (prefers-color-scheme: dark) {
  body {
    background: var(--dark-bg-color);
    color: var(--dark-text-color);
  }

  body.light {
    background: var(--light-bg-color);
    color: var(--light-text-color);
  }
}

@media (prefers-color-scheme: light) {
  body {
    background: var(--light-bg-color);
    color: var(--light-text-color);
  }

  body.dark {
    background: var(--dark-bg-color);
    color: var(--dark-text-color);
  }
}
```

Useful readings:
* [Editing your css for dark mode (Stackoverflow)](https://stackoverflow.com/questions/64960915/change-css-colors-based-on-body-class-dark-mode/64960981#64960981){:target="blank"}
* [Dark mode with TailwindCSS](https://tailwindcss.com/docs/dark-mode){:target="blank"}
