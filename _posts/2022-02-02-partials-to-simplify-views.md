---
layout: post
title: "Quick tip: Using Partials to Simplify Views"
author: Yaroslav Shmarov
tags: ruby-on-rails tldr layouts
thumbnail: /assets/thumbnails/rails-logo.png
---

Sometimes you want to have multiple views that share HTML (and render different content only deep inside the block of HTML).

For example, **modals**, **multi-step forms**, or a **wizard**:

![multistep-form.gif](/assets/images/multistep-form.gif)

Not to duplicate HTML, use [Partials to Simplify Views](https://guides.rubyonrails.org/layouts_and_rendering.html#using-partials-to-simplify-views){:target="blank"}. With `yield` and `do`-blocks.

### Before:

```ruby
# new.html.haml
<div class="modal">
  <div class="modal-header">
    New post
  </div>
  <div class="modal-body">
    <%= render "form", post: @post %>
  </div>
</div>
```

```ruby
# edit.html.haml
<div class="modal">
  <div class="modal-header">
    Edit post
  </div>
  <div class="modal-body">
    <%= render "form", post: @post %>
  </div>
</div>
```

### After:

```ruby
# shared/_modal.html.haml
<div class="modal">
  <div class="modal-header">
    <%= title %>
  </div>
  <div class="modal-body">
    <%= yield %>
  </div>
</div>
```

```ruby
# new.html.haml
<%= render "shared/modal", title: "New post" do %>
  <%= render "form", post: @post %>
<% end %>
```

```ruby
# edit.html.haml
<%= render "shared/modal", title: "Edit post" do %>
  <%= render "form", post: @post %>
<% end %>
```

Much cleaner, isn't it?! ;)

It is also very common to use [ViewCompoenent](https://viewcomponent.org/guide/getting-started.html#implementation){:target="blank"} for doing exactly this (rendering content inside an HTML block)!

= render layout: 'courses/course_wizard/step' do
