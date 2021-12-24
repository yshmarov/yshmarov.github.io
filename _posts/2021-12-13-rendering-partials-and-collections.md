---
layout: post
title: "TIP: Rendering partials and collections"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails tiny-tip action-view
thumbnail: /assets/thumbnails/html.png
---

### 1. Using shorthand syntax:

This:

```ruby
<% @inbox.messages.each do |message| %>
  <%= render partial: 'messages/message', locals: { message: message } %>
<% end %>
```

Equals this:

```ruby
<%= render @inbox.messages %>
```

### 2. Less magic = More control!

```ruby
<%= render @messages %>
<%= render partial: "messages/message", collection: @messages, locals: { a: "b" } %>
```

****

```ruby
<%= render @message %>
<%= render partial: "messages/message", locals: { message: @message, a: "b" } %>
```

### 3. Passing ONLY locals to a partial:

* Does not work:

```ruby
<%= render "layouts/foo", locals: { a: "b" } %>
```

* works:

```ruby
<%= render partial: "layouts/foo", locals: { a: "b" } %>
```

* also works:

```ruby
<%= render "layouts/foo", a: "b" %>
```

### 4. Check if a local variable is present

```ruby
local_assigns[:a].present?
# => true
local_assigns[:a].presence
# => "b"
local_assigns[:a]
# => "b"
```

Found this ^ one [here](https://stackoverflow.com/a/23018557/5695646){:target="blank"}

Resources:
* [ActionView::PartialRenderer](https://api.rubyonrails.org/classes/ActionView/PartialRenderer.html#class-ActionView::PartialRenderer-label-Rendering+the+default+case){:target="blank"}
* [Layouts and Rendering in Rails](https://guides.rubyonrails.org/layouts_and_rendering.html#rendering-collections){:target="blank"}
