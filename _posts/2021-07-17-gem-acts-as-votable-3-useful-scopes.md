---
layout: post
title: "gem acts_as_votable 3: vote search scopes"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails acts_as_votable
thumbnail: /assets/thumbnails/like.png
---

* this is part 3
* [part 2 of this post]({% post_url 2021-05-10-gem-acts-as-votable-2 %}){:target="blank"}
* [part 1 of this post]({% post_url 2021-05-03-gem-acts-as-votable %}){:target="blank"}

## Scopes - which Posts a User voted for

post.rb

```ruby
  scope :my_voted, -> (user) { where(id: user.find_voted_items.map(& :id)) }
  scope :my_un_voted, -> (user) { where.not(id: user.find_voted_items.map(& :id)) }
  scope :my_up_voted, -> (user) { where(id: user.find_up_voted_items.map(& :id)) }
  scope :my_down_voted, -> (user) { where(id: user.find_down_voted_items.map(& :id)) }
```

a view:

```ruby
<%= Post.my_voted(current_user).count %>
<%= Post.my_un_voted(current_user).count %>
<%= Post.my_up_voted(current_user).count %>
<%= Post.my_down_voted(current_user).count %>
```

## Scopes - which Users voted for a Post

a view:

```ruby
Liked by:
- @post.votes_for.up.by_type(User).voters.each do |user|
  = link_to user, user
Disliked by:
- @post.votes_for.down.by_type(User).voters.each do |user|
  = link_to user, user
```

```
<%= Post.first.votes_for.up.by_type(User).voters.pluck(:name) %>
```
