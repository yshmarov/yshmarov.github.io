---
layout: post
title: 'Semantic HTML in Ruby on Rails'
author: Yaroslav Shmarov
tags: rails html
thumbnail: /assets/thumbnails/html.png
---

Often when writing an HTML page we resort to `div` and `span`, whereas there are many other HTML tags that we just tend to overlook or forget.

Writing semantic HTML means actually using the right HTML tags for different parts of a page.

Semantic HTML is important for accessibility, screen readers, SEO. And just looks more professional ;)

Good resources on writing semantic HTML:
* [MDN HTML API](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)
* [CSS tricks:  How to Section Your HTML](https://css-tricks.com/how-to-section-your-html/)

### Example of utilizing semantic HTML in a Ruby on Rails app:

* `<header>`, `<main>`, `<footer>` in the body
* `<nav>` for navbar
* `<aside>` for sidebar (related links, advertisements)
* `<section>` for main content

```ruby
# app/views/layouts/application.html.erb
<body>
  <header>
    <nav>
      <%= render "shared/navbar" %>
    </nav>
  </header>
  <main>
    <%= render "shared/flash" %>
    <aside>
      <%= render "shared/sidebar" %>
    </aside>
    <section>
      <%= yield %>
    </section>
  </main>
  <footer>
    <%= render "shared/footer" %>
  </footer>
</body>
```

* unstiled list of links inside the `<nav>` for navigation

```ruby
# app/views/shared/_navbar.html.erb
<ul>
  <li>
    <%= link_to "Home", root_path %>
  </li>
  <li>
    <%= link_to "Posts", posts_path %>
  </li>
</ul>
```

* `<section>` should usually have a heading

```ruby
# app/views/posts/index.html.erb
<section>
  <h1>Posts</h1>
  <%= render @posts %>
</section>
```

```ruby
# app/views/posts/show.html.erb
<section>
  <h1>Post <%= @post.id %><h1>
  <%= render @post %>
</section>
```

* `<article>` - an object that makes sence outside of other context

```ruby
# app/views/posts/_post.html.erb
<article>
  <%= @post.title %>
  <%= @post.body %>
</article>
```

The above is my current-best approach.

If you have any suggestions on how to make it better, please tell me!
