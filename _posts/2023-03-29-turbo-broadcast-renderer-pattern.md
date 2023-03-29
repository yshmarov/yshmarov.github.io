---
layout: post
title: "Broadcaster pattern for Turbo Streams Broadcasts"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo broadcasts
thumbnail: /assets/thumbnails/turbo.png
---

[Previously]({% post_url 2021-12-09-turbo-hotwire-broadcasts %}){:target="blank"} I said that it's an **awful practice** to render a turbo stream broadcast form a **model**, and suggested doing it from a **controller**. That's better, however that makes the controller much more complex. I would like to introduce the **`Broadcaster`** pattern.

By moving your broadcasts rendering logic from a controller into the `app/services` directory, you can:
- ✅ clean up
- ✅ test in isolation
- ✅ trigger from console
- ✅ reuse in different places

Here's an example of moving broadcast logic from a controller into `app/services/broadcasters/*`:

```diff
def create
  if @record.save
-    Turbo::StreamsChannel.broadcast_action_later_to(:posts_list, target: :posts, action: :prepend, partial: 'posts/post', locals: { post: post } )
-    Turbo::StreamsChannel.broadcast_update_to(:posts_list, target: :posts_counter, html: Post.count )
+    Broadcasters::Posts::Created.new(post).call
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
```

Create a Service Object that would contain the above broadcasting logic:

```ruby
# app/services/broadcasters/posts/created.rb
class Broadcasters::Posts::Created
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def call
    # as many broadcasts as you wish!
    prepend_post
    update_counter
  end

  def prepend_post
    Turbo::StreamsChannel.broadcast_action_later_to(
      :posts_list,
      target: :posts,
      action: :prepend,
      partial: 'posts/post',
      locals: { post: post }
    )
  end

  def update_counter
    Turbo::StreamsChannel.broadcast_update_to(
      :posts_list,
      target: :posts_counter,
      html: Post.count
    )
  end
end
```

Now you can trigger this broadcasters from anywhere in your app:

```ruby
# rails console
post = Post.last
Broadcasters::Posts::Created.new(post).call
```

That's it!

P.S. For everything to work, sometimes you might have to include specific Rails helpers in your service object:

```diff
class Broadcasters::Posts::Created
+  include ActionView::RecordIdentifier
+  include Turbo::StreamsHelper
+  include Rails.application.routes.url_helpers
```