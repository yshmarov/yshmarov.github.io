---
layout: post
title: "Tailwind CSS Bottom Navigation"
author: Yaroslav Shmarov
tags: rails tailwindcss animation page-transition
thumbnail: /assets/thumbnails/tailwindcss.png
---

Mobile apps usually have **bottom**, not top navigation.

Hide the top navbar on a mobile screen and show a footer nav to give your app a mobile feel!

![Bottom navigation](/assets/images/sticky-mobile-footer.png)

Here's how a layout with a sticky footer that is always on the bottom can look like:

```html
<!DOCTYPE html>
<html>
  <%= render 'shared/head' %>
  <body class="text-gray-200 flex flex-col min-h-screen bg-sky-950">
    <header class="sticky top-0">
      <%= render 'shared/navbar' %>
    </header>
    <main class="flex-grow p-4 md:p-8 mx-auto max-w-7xl">
      <%= yield %>
    </main>

    <!-- FOOTER START -->
    <footer class="sticky bottom-0 px-6 py-3 w-full flex items-center md:hidden justify-around bg-sky-900">
      <%= link_to playlists_path do %>
        <%= inline_svg_tag 'svg/playlist.svg', class: 'h-8 w-8 text-gray-200' %>
      <% end %>
      <%= link_to posts_path do %>
        <%= inline_svg_tag 'svg/default_post.svg', class: 'h-8 w-8 text-gray-200' %>
      <% end %>
      <%= link_to root_path do %>
        <%= image_tag 'logo.png', class: 'w-8 h-8' %>
      <% end %>
      <%= link_to search_path do %>
        <%= inline_svg_tag 'svg/search.svg', class: 'h-8 w-8 text-gray-200' %>
      <% end %>
      <%= link_to user_path(current_user) do %>
        <%= image_tag current_user.image, class: 'w-8 h-8 rounded-full', alt: current_user.email if current_user.image? %>
      <% end %>
    </footer>
    <!-- FOOTER END -->

  </body>
</html>
```

That's it!
