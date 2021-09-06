---
layout: post
title: "Polymorphism 101. Part 1 of 3. Polymorphic Comments."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails polymorphism polymorphic-associations
thumbnail: /assets/thumbnails/polymorphism-sign.png
---

My current best approach for creating polymorphic child records based on the best bits from all other approaches.

This example - creating polymorphic `Comments` table that can be integrated easily into any model.

![polymorphic-comments.gif](/assets/images/polymorphic-comments.gif)

# Step 1. Add polymorphic comments to the application

console
```
rails g migration create_comments content:text commentable:references{polymorphic}
```
app/models/comment.rb
```
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  validates :content, presence: true
  def to_s
    content
  end
end 
```
app/controllers/comments_controller.rb
```
class CommentsController < ApplicationController
  before_action :set_commentable

  def new
    @comment = Comment.new
  end

  def create
    @comment = @commentable.comments.build(comment_params)
    if @comment.save
      redirect_to @commentable, notice: "Comment created"
    else
      render :new
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      redirect_to @commentable, notice: "Comment deleted"
    else
      redirect_to @commentable, alert: "Something went wrong"
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def set_commentable
    if params[:user_id].present?
      @commentable = User.find_by_id(params[:user_id])
    elsif params[:post_id].present?
      @commentable = Post.find_by_id(params[:post_id])
    end
  end
end
```

app/views/comments/_form.html.erb
```
<%= form_for [@commentable, @comment] do |f| %>
  <% if @comment.errors.any? %>
    <% @comment.errors.each do |error| %>
      <%= error.full_message %>
    <% end %>
  <% end %>

  <%= f.label :content %>
  <%= f.text_area :content %>
  <%= f.submit %>
<% end %>
```

app/views/comments/_index.html.erb
```
Comments:
<%= @commentable.comments.count %>
<% commentable.comments.each do |comment| %>
  <%= comment.created_at.strftime('%d-%m-%Y %H:%m') %>
  <%= link_to "Destroy", [@commentable, comment], method: :delete %>
  <%= simple_format(comment.content) %>
  <br>
<% end %>
```
app/views/comments/new.html.erb
```
New Comment for:
<%= link_to @commentable, @commentable %>
<%= render 'comments/form' %>
```
routes.rb
```
  resources :posts do
    resources :comments, only: [:new, :create, :destroy]
  end
```

# Step 2. Add polymorphic comments to a model. For example `post`

app/controllers/posts_controller.rb
```
  def show
    @commentable = @post
    @comment = Comment.new
  end
```
app/models/post.rb
```
   has_many :comments, as: :commentable, dependent: :destroy
```
app/views/posts/show.html.erb - with a link to create a comment
```
<%= link_to "New Comment", new_post_comment_path(@commentable, @comment) %>
<%= render partial: "comments/index", locals: {commentable: @commentable} %>
```
app/views/posts/show.html.erb - alternative - with a comments form in the view
```
<%= render template: "comments/new" %>
<%= render partial: "comments/index", locals: {commentable: @commentable} %>
```

# Notes

In `comments_controller` you have to update the action `set_commentable` with each model that you want to make commentable.
This is better than creating a separate `comments_controller` for each commentable model.

To add polymorphic to one more model, repeat `step 2` by replacing the word `post` with whatever model you want.

# Bonus: Save which user created a comment

1. 
```
rails g migration add_user_references_to_comments user:references
```

2. To save `current_user` who created a comment, in `comments_controller` `create` action above line `if @comment.save` add the line
```
@comment.user_id = current_user.id
```

# Using `simple_form`
```
<%= simple_form_for [@commentable, @comment] do |f| %>
  <%= f.error_notification %>
  <%= f.error_notification message: f.object.errors[:base].to_sentence if f.object.errors[:base].present? %>

  <%= f.input :content, label: false, required: true %>
  <%= f.button :submit %>
<% end %>
```
