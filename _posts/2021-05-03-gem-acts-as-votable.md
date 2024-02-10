---
layout: post
title: "gem acts_as_votable 1: Like and Dislike posts with Vanilla JS"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails acts_as_votable ajax js-erb
thumbnail: /assets/thumbnails/like.png
youtube_id: gbbGhBUBftE
---

NO jQuery. ONLY vanilla JS

## Final result - logged in users can vote up/down on posts. Autorefresh votes count

****

## HOWTO:

## 1. Prerequisites:

1. scaffold posts title
2. gem devise, create users

## 2. Install [gem acts_as_votable](https://github.com/ryanto/acts_as_votable){:target="blank"}

```ruby
# console
rails g scaffold post body:text
bundle add acts_as_votable
rails generate acts_as_votable:migration
rails g migration AddCachedVotesToPosts
rails db:migrate
```

```ruby
class AddCachedVotesToPosts < ActiveRecord::Migration[6.1]
  def change
    change_table :posts do |t|
      t.integer :cached_votes_total, default: 0
      t.integer :cached_votes_score, default: 0
      t.integer :cached_votes_up, default: 0
      t.integer :cached_votes_down, default: 0
      t.integer :cached_weighted_score, default: 0
      t.integer :cached_weighted_total, default: 0
      t.float :cached_weighted_average, default: 0.0
    end

    # Uncomment this line to force caching of existing votes
    # Post.find_each(&:update_cached_votes)
  end
end
```

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  acts_as_votable
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  acts_as_voter
end
```

## 3. Ajax votes

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all.order(cached_votes_score: :desc)
  end

  def like
    @post = Post.find(params[:id])
    if current_user.voted_up_on? @post
      @post.downvote_by current_user
    elsif current_user.voted_down_on? @post
      @post.upvote_by current_user
    else #not voted
      @post.upvote_by current_user
    end
    respond_to do |format|
     format.js
    end 
  end
end
```
```ruby
# config/routes.rb
  resources :posts do
    member do
      patch "like", to: "posts#like"
    end
  end
```
```ruby
# app/views/posts/index.html.erb
<h1>Posts</h1>
<% @posts.each do |post| %>
  <%= post.name %>
  <% if current_user %>
    <%= content_tag "div", id: "like-link-#{post.id}" do %>
      <%= render 'posts/like_link', post: post %>
    <% end %>
  <% end %>
  <hr>
<% end %>
```
```ruby
# app/views/posts/_like_link.html.erb
<%= link_to like_post_path(post), method: :patch, remote: true, id: "like-link-#{post.id}" do %>
  <% if current_user.voted_up_on?(post) %>
    UP voted
    <b>
      <%= post.cached_votes_score %>
    </b>
    DOWN vote
  <% elsif current_user.voted_down_on?(post) %>
    UP vote
    <b>
      <%= post.cached_votes_score %>
    </b>
    DOWN voted
  <% else %>
    UP
    <b>
      <%= post.cached_votes_score %>
    </b>
    DOWN
  <% end %>
<% end %>
```
```js
// like.js.haml
document.getElementById("like-link-#{@post.id}").innerHTML = "#{j render "posts/like_link", post: @post}";
```
```js
// like.js.erb
document.getElementById("like-link-<%= @post.id %>").innerHTML = "<%= j render "posts/like_link", post: @post %>";
```

## 4. Other way to add ajax votes

```ruby
# posts_controller.rb
  def upvote
    @post = Post.find(params[:id])
    @post.upvote_by current_user
    respond_to do |format|
      format.js
    end 
  end

  def downvote
    @post = Post.find(params[:id])
    @post.downvote_by current_user
    respond_to do |format|
      format.js
    end 
  end
```
```ruby
# app/views/posts/_downvote_link.html.erb
<%= link_to downvote_post_path(post), method: :patch, remote: true, id: "downvote-#{post.id}" do %>
  Liked. Go Dislike
<% end %>
```
```ruby
# app/views/posts/_like_count.html.erb
<%= post.cached_votes_score %> 
```
```ruby
# app/views/posts/_upvote_link.html.erb
<%= link_to upvote_post_path(post), method: :patch, remote: true, id: "upvote-#{post.id}" do %>
  Disliked. Go Like
<% end %>
```
```js
// app/views/posts/downvote.js.erb
document.getElementById("like-count-<%= @post.id %>").innerHTML = "<%= j render "posts/like_count", post: @post %>";
document.getElementById("downvote-<%= @post.id %>").innerHTML = "<%= j render "posts/upvote_link", post: @post %>";
```
```ruby
# app/views/posts/index.html.erb
  <% if current_user.voted_up_on? post %>
    <%= render 'downvote_link', post: post %>
  <% elsif current_user.voted_down_on? post %>
    <%= render 'upvote_link', post: post %>
  <% end %>
  <%= content_tag "div", id: "like-count-#{post.id}" do %>
    <%= render 'posts/like_count', post: post %>
  <% end %>
```
```js
// app/views/posts/upvote.js.erb
document.getElementById("like-count-<%= @post.id %>").innerHTML = "<%= j render "posts/like_count", post: @post %>";
document.getElementById("upvote-<%= @post.id %>").innerHTML = "<%= j render "posts/downvote_link", post: @post %>";
```
```ruby
# config/routes.rb
  patch "upvote", to: "posts#upvote"
  patch "downvote", to: "posts#downvote"
```

## 5. Improve flow

app/views/posts/_downvote_link.html.erb
```
<%= content_tag "div", id: "downvote-#{post.id}" do %>
  Liked
  <%= link_to downvote_post_path(post), method: :patch, remote: true do %>
    Go Dislike
  <% end %>
<% end %>
```
app/views/posts/_upvote_link.html.erb
```
<%= content_tag "div", id: "upvote-#{post.id}" do %>
  Disliked
  <%= link_to upvote_post_path(post), method: :patch, remote: true do %>
    Go Like
  <% end %>
<% end %>
```
app/views/posts/like.js.erb
```
document.getElementById("like-link-<%= @post.id %>").innerHTML = "<%= j render "posts/like_link", post: @post %>";
document.getElementById("like-count-<%= @post.id %>").innerHTML = "<%= j render "posts/like_count", post: @post %>";
```

## That's it!
