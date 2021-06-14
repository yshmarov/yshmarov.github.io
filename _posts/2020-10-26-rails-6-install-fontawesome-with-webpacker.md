---
layout: post
title: 'How to Install FontAwesome with Yarn and Webpacker in Rails 6?'
author: Yaroslav Shmarov
tags: 
- fontawesome
- webpacker
- ruby on rails 6
thumbnail: https://www.drupal.org/files/project-images/font_awesome_logo.png
---

[Using FontAwesome yarn package manager](https://fontawesome.com/v5.15/how-to-use/on-the-web/setup/using-package-managers){:target="blank"}

# **1. console:**

```
yarn add @fortawesome/fontawesome-free
```

# **2. javascript/packs/application.js:**

```
import "@fortawesome/fontawesome-free/css/all"
```

# **3. Check if it works:**

Add couple of icons in any .html.erb (view) file:
```
<i class="far fa-address-book"></i>
<i class="fab fa-github"></i>
```

# Tips and tricks

* Use smth like `fa-3x` for font size.
* Use `fa-spin` to make any icon spin. [Animating Icons](https://fontawesome.com/v5.15/how-to-use/on-the-web/styling/animating-icons){:target="blank"}
* Use it in a link with a block
```
<%= link_to root_path do %>
  <i class="far fa-gem fa-spin fa-3x"></i>
  Home
<% end %>
```

That's it!😊

****

# **Relevant links:** 

* [see all FontAwesome Icons here](https://fontawesome.com/icons?d=gallery&m=free){:target="blank"}
* [Yarn package](https://yarnpkg.com/package/@fortawesome/fontawesome-free){:target="blank"}