---
layout: post
title: "gem acts_as_votable 2: reddit-style up and down voting"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails acts_as_votable
thumbnail: /assets/thumbnails/like.png
---

Also see [part 1 of this post]({% post_url 2021-05-03-gem-acts-as-votable %}){:target="blank"}

Final result:
![f](/assets/gem-acts-as-votable/reddit-votable-gif-2.gif)

## HOWTO:

routes.rb
```
  resources :posts do
    member do
      patch "upvote", to: "posts#upvote"
      patch "downvote", to: "posts#downvote"
    end
  end
```
posts/posts_controller.rb
```
class PostsController < ApplicationController
  def index
    @posts = Post.all.order(cached_votes_score: :desc)
  end

  def upvote
    @post = Post.find(params[:id])
    if current_user.voted_up_on? @post
      @post.unvote_by current_user
    else
      @post.upvote_by current_user
    end
    render "vote.js.erb"
  end

  def downvote
    @post = Post.find(params[:id])
    if current_user.voted_down_on? @post
      @post.unvote_by current_user
    else
      @post.downvote_by current_user
    end
    render "vote.js.erb"
  end

end
```
posts/index.html.erb
```
<h1>Posts</h1>
<% @posts.each do |post| %>
  <%= post.name %>
  <% if current_user %>
    <br>
    <%= render 'posts/upvote_link', post: post %>
    <%= render 'posts/like_count', post: post %>
    <%= render 'posts/downvote_link', post: post %>
  <% end %>
  <hr>
<% end %>
```
posts/_upvote_link.html.erb
```
<%= content_tag "div", id: "upvote-#{post.id}" do %>
  <%= link_to upvote_post_path(post), method: :patch, remote: true, data: { disable_with: "voting..." } do %>
    <% if current_user.voted_up_on? post %>
      <i class="far fa-thumbs-up" style="color: green;"></i>
      unvote
    <% else %>
      <i class="far fa-thumbs-up"></i>
      upvote
    <% end %>
  <% end %>
<% end %>
```
posts/_downvote_link.html.erb
```
<%= content_tag "div", id: "downvote-#{post.id}" do %>
  <%= link_to downvote_post_path(post), method: :patch, remote: true, data: { disable_with: "voting..." } do %>
    <% if current_user.voted_down_on? post %>
      <i class="far fa-thumbs-down" style="color: red;"></i>
      unvote
    <% else %>
      <i class="far fa-thumbs-down"></i>
      downvote
    <% end %>
  <% end %>
<% end %>
```
posts/_like_count.html.erb
```
<%= content_tag "div", id: "like-count-#{post.id}" do %>
  <%= post.cached_votes_score %>
<% end %>
```
posts/vote.js.erb
```
document.getElementById("like-count-<%= @post.id %>").innerHTML = "<%= j render "posts/like_count", post: @post %>";
document.getElementById("downvote-<%= @post.id %>").innerHTML = "<%= j render "posts/downvote_link", post: @post %>";
document.getElementById("upvote-<%= @post.id %>").innerHTML = "<%= j render "posts/upvote_link", post: @post %>";
```
