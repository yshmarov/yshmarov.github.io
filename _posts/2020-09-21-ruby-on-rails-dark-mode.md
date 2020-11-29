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
thumbnail: https://www.clipartkey.com/mpngs/m/131-1311951_transparent-white-moon-png-transparent-crescent-moon-symbol.png
---

You don't need to migrate columns, have a current user, or add new stylesheets.

Here's how it works on my website:

![dark-mode](/assets/2020-09-21-ruby-on-rails-dark-mode/dark-mode.gif)

[Live Demo - try to click yourself!](https://saas.corsego.com/){:target="blank"}

### Here's how to do it:

* Set a `body` `class` and create links to selecting a `theme`:

```
# application.html.erb

<body class="<%= cookies[:theme] %>">

  <% if cookies[:theme] == "light" %>
    <%= link_to "go dark", root_path(theme: "dark") %>
  <% else %>
    <%= link_to "go light", root_path(theme: "light") %>
  <% end %>
  
  <%= yield %>

</body>
```

* Persist `theme` in `cookies`:

```
# application_controller.rb

before_action :set_theme

def set_theme
  if params[:theme].present?
    theme = params[:theme].to_sym
    # session[:theme] = theme
    cookies[:theme] = theme
    redirect_to(request.referrer || root_path)
  end
end
```

* Update your css file accordingly:

```
# application.scss

body.light {
  color: black;
  background-color: white;
}
body.dark {
  color: white;
  background-color: black;
}
```

Next step - 
[Editing your css for dark mode (Stackoverflow)](https://stackoverflow.com/questions/64960915/change-css-colors-based-on-body-class-dark-mode/64960981#64960981){:target="blank"}
