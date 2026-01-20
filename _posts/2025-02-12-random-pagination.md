---
layout: post
title: "Random Pagination"
author: Yaroslav Shmarov
tags: pagination pagy
thumbnail: /assets/thumbnails/rails-logo.png
---

Sometimes you want to display records in a random order, but also paginate them.

`order("RANDOM()")` can return duplicates on next pages.

My solution is to set a random seed, and then order by a random value set with that seed.

```ruby
  def index
    cookies[:seed] ||= SecureRandom.random_number
    @posts = Post.order(Arel.sql("random()")).from("(SELECT setseed(#{cookies[:seed]})) as seed_setup, posts")
    @pagy, @posts = pagy_countless(@posts, items: 24)
  end
```

This will return a random order of posts, and the same order on each page.
