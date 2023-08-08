---
layout: post
title: "TailwindCSS on Rails 01: Responsive layout with sidebar"
author: Yaroslav Shmarov
tags: rails tailwindcss
thumbnail: /assets/thumbnails/tailwindcss.png
---

> Tailwind CSS: It looks awful, and it works.
>
> Adam Wathan, TailwindCSS creator

As of Rails 7, you can automatically install [TailwindCSS](https://tailwindcss.com/docs/) when generating a new rails app by running `rails new -c=tailwind -d=postgresql`. Adam also personally helped with the default styles.

I am super excited that [just like me](https://rubyonrails.org/world/agenda/day-2/8-yaroslav-shmarov-session), Adam will be also [speaking on Rails World](https://rubyonrails.org/world/agenda/day-2/7b-adam-wathan-session).

In this mini-series I will cover the main aspects of using TailwindCSS when building a Rails app.

When you create a new Rails app, first of all you want to figure out navigation (navbar, sidebar, footer) and UI responsiveness (make it work on all screen sizes).

Let's build a responsive layout with a sidebar that is replaced by a dropdown on a small screen:

![Responsive Layout with sidebar using TailwindCSS](/assets/images/01-tailwind-responsive-layout.gif)

Here's the HTML for this layout:

```html
<!-- app/views/layouts/application.html.erb -->
<body class="bg-green-200">
  <header class="bg-slate-500 flex justify-between p-4 sticky top-0 h-20 items-center">
    <div>
      logo
    </div>
    <div>
      current_user.email
    </div>
    <div class="md:hidden">
      ☰
    </div>
  </header>
  
  <div class="flex flex-grow">
    <nav class="bg-slate-400 w-1/6 md:flex flex-col hidden justify-between p-4 text-center sticky top-20 h-[calc(100vh-80px)]">
      <div>
        right sidebar TOP
      </div>
      <div>
        right sidebar BOTTOM
      </div>
    </nav>
    <main class="w-5/6 p-4 bg-rose-300 flex-grow">
      <% (1..100).each do |i| %>
        <p><%= i %></p>
      <% end %>
      <%= yield %>
    </main>
  </div>
</body>
```

*Colors are present for you to see the different elements.*

Now, it's up to you to give unique styles for each page inside `yield`.

For example, for a page with centered, not full-width content you can do:

```html
<!-- app/views/posts/new.html.erb -->
<div class="mx-auto max-w-md">
  New Post
  <%= render "form" %>
</div>
```

That's it! 🤠

Next step: Make the navbar dropdown actually work on small screen when the sidebar is hidden 🙈
