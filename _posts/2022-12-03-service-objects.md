---
layout: post
title: "Use Service Objects"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails service-objects
thumbnail: /assets/thumbnails/ruby.png
---

Service Objects are basically ruby scripts that you can run in your Rails app.

It's a great way to **abstract scripts that you can run anywhere from your app.** You can run it from any controller action, a model, from a job, or even from another Service Object!

This is a common way to abstract API calls to external services or business logic.

Chances are high, that in any real-life production application you will encounter `/app/services/` folder. Common aliases are `/app/integrations/`, `/app/operations/`.

### Minimal script setup example:

```ruby
# app/services/publish_post.rb
class PublishPost
  def initialize(post, user)
    @post = post
    @user = user
  end

  def call
    return if @post.published!

    @post.update(user: @user)
    @post.published!
  end
end
```

Call the command:

```ruby
post = Post.first
user = User.first
PublishPost.new(post, user).call
```

### Advanced script setup example:

```ruby
# app/services/posts/publish.rb
require 'abc'

module Posts
  class Publish
    attr_reader :post, :user

    def initialize(post, user)
      @post = post
      @user = user
    end

    def call
      return unless callable?

      @post.update(user: @user)
      @post.published!
    end

    private

    def callable?
      !@post.published?
    end
  end
end
```

Call the command:

```ruby
post = Post.first
user = User.first
Posts::Publish.new(post, user).call
```

That's it!
