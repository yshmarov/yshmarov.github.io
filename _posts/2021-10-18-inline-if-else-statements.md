---
layout: post
title: "Tiny Tip: Inline if-else statements"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails if-else tiny-tip
thumbnail: /assets/thumbnails/curlybrackets.png
---

a) This
```ruby
  if post.published?
    'published'
  else
    'draft'
  end
```
can be written like this
```ruby
  post.published? 'published' : 'draft'
```

b) This
```ruby
if post.published?
  'published'
elsif post.draft?
  'draft'
else
  'archived'
end
```
can be written like this
```ruby
  post.published? ? 'published' : post.draft? 'draft' : 'archived'
```
