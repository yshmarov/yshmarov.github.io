---
layout: post
title: Finding similar/related posts/products based on matching tags
author: Yaroslav Shmarov
tags: ruby rails tags content algorythm similar-products similar-posts related-products related-posts
thumbnail: /assets/thumbnails/ruby.png
---

When creating a content website on an ecommerce store, you will often want to show **similar** content/products:

![Amazon similar products](/assets/images/amazon-similar-products.png)

An easy way to do it is to introduce **tags**, and find "similar" records by the amount of matching tags.

This is how I show similar posts on [SupeRails.com](https://superails.com/):

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  def similar_posts
    Post.joins(:tags)
        .where.not(id:) # do not show current post within similar records
        .where(tags: { id: tags.ids })
        .group('posts.id')
        .select('posts.*, COUNT(tags.id) AS tags_count')
        .order(tags_count: :desc)
        .limit(5) # max similar records
  end
end
```

Now you can call

```ruby
post = Post.first
post.similar_posts
```

### Testing

```ruby
# test/models/similar_posts_test.rb
require 'test_helper'

class SimilarPostsTest < ActiveSupport::TestCase
  test 'similar_posts returns correct posts' do
    post = Post.create(title: 'Test Post')
    tag1 = Tag.create(title: 'Tag 1')
    tag2 = Tag.create(title: 'Tag 2')
    tag3 = Tag.create(title: 'Tag 3')

    post.tags << tag1
    post.tags << tag2

    similar_post1 = Post.create(title: 'Similar Post 1')
    similar_post1.tags << tag1

    similar_post2 = Post.create(title: 'Similar Post 2')
    similar_post2.tags << tag2

    unrelated_post = Post.create(title: 'Unrelated Post')
    unrelated_post.tags << tag3

    similar_posts = post.similar_posts

    assert_includes similar_posts, similar_post1
    assert_includes similar_posts, similar_post2
    assert_not_includes similar_posts, unrelated_post
  end
end
```

### How to assign tags to posts?

Traditionally, content creators can assign tags manually (jekyll blog, dev.to, youtube):

![add tags to a youtube video](/assets/images/youtube-video-creation-tags-input.png) 

You can also use different software to assign tags automatically:

![chatgpt prompt to generate tags based on a text](/assets/images/chatgpt-text-keywords-prompt.png)

That's it!
