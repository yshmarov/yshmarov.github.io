---
layout: post
title: "Button to update status attribute of a table"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails polymorphism polymorphic-associations
thumbnail: /assets/thumbnails/button-thumbnail.png
---

Mission: add buttons to change the `status` of a `post`

![change-status.gif](/assets/images/change-status.gif)

HOWTO:

migration - add `status` column to `posts`

```
add_column :posts, :status, :string, null: false, default: "planned"
```

post.rb - list available statuses

```ruby
  validates :status, presence: true
  STATUSES = %i[planned progress done].map(&:to_s).freeze
  validates :quote_requestor, inclusion: { in: Post::STATUSES }
```

posts_controller.rb - add action to change status

```
  def change_status
    @post = Post.find(params[:id])
    if params[:status].present? && Post::STATUSES.include?(params[:status].to_sym)
      @post.update(status: params[:status])
    end
    redirect_to @post, notice: "Status updated to #{@post.status}"
  end
```
routes.rb
```
  resources :posts do
    member do
      patch :change_status
    end
  end
```
posts/show.html.erb
```
  <% Post::STATUSES.each do |status| %>
    <%= link_to change_status_post_path(@post, status: status), method: :patch do %>
      <%= status %>
    <% end %>
  <% end %>
```
or with a block
```
  <% Post::STATUSES.each do |status| %>
    <%= link_to_unless post.status.eql?(status.to_s), status, change_status_post_path(post, status: status), method: :patch %>
  <% end %>
```
