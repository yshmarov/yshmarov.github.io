---
layout: post
title: "REVISED: Polymorphism 101. Part 4 of 3. Polymorphic Comments"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails polymorphism polymorphic-associations comments
thumbnail: /assets/thumbnails/polymorphism-sign.png
---

Final result example:
![polymorphic nested commits](/assets/polymorphic_nested_comments/nested_comments.png)

NOTE: I don't like this code any more. There's a newer post available ;)

### 1. migration

1 console
```ruby
rails generate model Comment user:references body:text commentable:references{polymorphic} deleted_at:datetime:index
```

2 db/migrate/20210711135608_create_comments.rb
```ruby
class CreateComments < ActiveRecord::Migration[6.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false
      t.text :body
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :comments, :deleted_at
  end
end
```

### 2. models

3 app/models/comment.rb
```ruby
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  has_many :comments, as: :commentable
  validates :body, presence: true
  validates :body, length: { minimum: 5 }

  def destroy
    update(deleted_at: Time.zone.now)
  end
end
```

4 app/models/post.rb
```ruby
class Post < ApplicationRecord
  has_many :comments, as: :commentable
end
```

### 3. controllers

5 config/routes.rb
```ruby
  resources :posts, except: :index do
    resources :comments,  only: %i[new create destroy], module: :posts
  end

  resources :comments, only: [] do
    resources :comments,  only:   %i[new create destroy], module: :comments
  end
```

6 app/controllers/comments_controller.rb
```ruby
class CommentsController < ApplicationController
  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user
    if @comment.save
      respond_to do |format|
        # format.html { redirect_to @commentable }
        format.html { redirect_back(fallback_location: root_url) }
        format.js # create.js.erb
      end
    else
      redirect_to @commentable, alert: 'Comment could not be created.'
    end
  end

  def destroy
    @comment = @commentable.comments.find(params[:id])
    @comment.destroy # update(deleted_at: Time.zone.now)
    redirect_back(fallback_location: root_url)
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
```

7 app/controllers/comments/comments_controller.rb
```ruby
class Comments::CommentsController < CommentsController
  before_action :set_commentable

  def new
    @comment = current_user.comments.new(commentable: @commentable)
  end

  private

  def set_commentable
    @commentable = Comment.find(params[:comment_id])
  end
end
```

8 app/controllers/posts/comments_controller.rb
```ruby
class Posts::CommentsController < CommentsController
  before_action :set_commentable

  private

  def set_commentable
    @commentable = Post.friendly.find(params[:post_id])
  end
end
```

9 app/controllers/posts_controller.rb
```ruby
def show
  @post = Post.includes(:comments).friendly.find(params[:id])
end
```

### 4.views

10 app/javascript/stylesheets/application.scss
```
.display-none {
  display: none;
}

.comment {
  margin: 1em 0em 1em 1em;
  padding-left: 1em;
  border-left: 2px solid lightgray;
}
```

11 app/views/comments/_comment.html.erb
```ruby
<%= content_tag :div, id: dom_id(comment), class: 'comment' do %>
  <% if comment.deleted_at? %>
    <strong>[deleted]</strong>
  <% else %>
    <strong><%= comment.user.email %></strong>
    <p><%= comment.body %></p>
  <% end %>

  <div class='links'><small>
    <%= link_to 'Reply', [:new, comment, :comment], remote: true %>
    <% if current_user == comment.user %>
      <%= link_to 'Delete', [comment.commentable, comment], method: :delete, data: { confirm: 'Are you sure?' } %>
    <% end %>
  </small></div>

  <%= render 'comments/form', commentable: comment, comment: Comment.new %>
  <%= render comment.comments %>
<% end %>
```

12 app/views/comments/_form.html.erb
```ruby
<%= form_with model: [commentable, comment], id: dom_id(commentable, 'form'), class: 'display-none' do |form| %>
  <%= form.text_area :body, placeholder: 'Add a comment', style: "width: 100%", rows: 5, required: true %>
  <%= form.submit %>
<% end %>
```

13 app/views/comments/create.js.erb
```ruby
var form = document.querySelector("#<%= dom_id(@commentable, 'form') %>")
if (form != null) {
  form.classList.toggle("display-none")
}

var comments = document.querySelector("#<%= dom_id(@commentable) %>")
if (comments == null) {
  comments = document.querySelector("#comments")
}
comments.insertAdjacentHTML('beforeend', '<%= j render 'comments/comment', commentable: @commentable, comment: @comment %>')
```

14 app/views/comments/new.js.erb
```ruby
var form = document.querySelector('#<%= dom_id(@commentable, 'form') %>')
form.classList.toggle('display-none')
```

15 app/views/posts/show.html.erb
```ruby
<p><%= render 'comments/form', commentable: @post, comment: Comment.new %></p>
<%= link_to "Add Comment", [:new, @post, :comment], remote: true %> 

<h2>Comment</h2>
<div id='comments'>
  <%= render @post.comments %>
</div>
```
