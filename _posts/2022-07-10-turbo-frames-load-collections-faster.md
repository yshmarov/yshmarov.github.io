---
layout: post
title: "Use Turbo Frames to load collections faster"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails turbo hotwire
thumbnail: /assets/thumbnails/turbo.png
---

Sometimes loading a collection of partials can take LOOOOONG.

One **new** way to address that issues is loading each partial in a turbo_frame.

This way each partial can be loaded in a separate request **at it's own pace** without slowing the whole page down.

```diff
# app/views/posts/index.html.erb
<% @posts.each do |post| %>
-  <%= render partial: "posts/post", locals:{ post: post } %>
+  <%= turbo_frame_tag post, src: post_path(post), loading: :lazy, turbo_frame: "_top" do %>
+    Loading...
+  <% end %>
<% end %>
```

Wrap the post view into a `turbo_frame_tag`:

```ruby
# app/views/posts/show.html.erb
<%= turbo_frame_tag post do %>
  <%= post.title %>
  <%= post.body %>
<% end %>
```

Finally, instead of rendering the template `show.html.erb` we will use the action to render the `_post.html.erb` partial:

```ruby
# app/controllers/posts_controller.rb
  def index
    @posts = Post.all
  end

  def show
    post = Post.find(params[:id])
    render partial: 'posts/post', locals: { post: }
  end
```

If you want to reserve the `#show` action for the default use (rendering `show.html.erb`), consider generating a separate route for the turbo_frame-loaded _post partial.

To increase loading performance even more, the next step would be to replace the partial with a ViewComponent, as ViewComponents load faster than partials.
