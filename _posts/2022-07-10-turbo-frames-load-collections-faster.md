---
layout: post
title: "Load partials async with Turbo Frames"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails turbo hotwire
thumbnail: /assets/thumbnails/turbo.png
---

Sometimes loading a collection of partials can take LOOOOONG.

🤔 What if we leverage `turbo_frames` `src` and load each partial from a collection as a separate request?

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

```diff
# app/views/posts/show.html.erb
+<%= turbo_frame_tag post do %>
  <%= post.title %>
  <%= post.body %>
+<% end %>
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

Result:

**Before**: Sending 1 request:
![1-request.gif](/assets/images/1-request.gif)

**After**: Sending 101 requests:
![101-request.gif](/assets/images/101-request.gif)

⁉️🤔 So there's the question: `1` **heavy** request OR `100` **light** requests?

If you want to reserve the `#show` action for the default use (rendering `show.html.erb`), consider generating a separate route for the turbo_frame-loaded _post partial.

To increase loading performance even more, the next step would be to replace the partial with a ViewComponent, as ViewComponents load faster than partials.
