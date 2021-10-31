---
layout: post
title: "RE-REVISED: Polymorphism 101. Part 5 of 3. Even better Polymorphic Comments"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails polymorphism polymorphic-associations comments
thumbnail: /assets/thumbnails/polymorphism-sign.png
---

Final result example:
![polymorphic nested commits](/assets/images/nested-comments.gif)

Note: This is a clean CRUD approach. 

No responsive behaviours (they can be added with TURBO in the future).

Prerequisites:
* Rails 7 (`button_to delete`, `render :new, status: :unprocessable_entity`)
* Devise for Users
* Flash messages rendered via `app/views/shared/_flash`
* An Inboxes model (to which we will connect polymorphic comments)

* 1. A migration for comments
console
```sh
rails generate model Comment user:references body:text commentable:references{polymorphic} deleted_at:datetime:index
```

* 2. The Comment model. 

app/models/comment.rb
```ruby
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true, inverse_of: :comments
  has_many :comments, as: :commentable, dependent: :destroy

  MIN_BODY_LENGTH = 2
  MAX_BODY_LENGTH = 1000

  validates :body, presence: true
  validates :body, length: { minimum: MIN_BODY_LENGTH, maximum: MAX_BODY_LENGTH }

  # soft delete
  def destroy
    update(deleted_at: Time.zone.now)
  end

  def find_top_parent
    return commentable unless commentable.is_a?(Comment)

    commentable.find_top_parent
  end
end
```

* 3. Inbox - Comment relationships

app/models/inbox.rb
```ruby
  has_many :comments, -> { order(created_at: :desc) }, as: :commentable, dependent: :destroy, inverse_of: :commentable
```

* 4. We will have 3x comments_controller

config/routes.rb
```ruby
  resources :comments, only: [] do
    resources :comments, only: %i[new create destroy], module: :comments
  end

  resources :inboxes do
    resources :comments, only: %i[new create destroy], module: :inboxes
  end
```

* 1 general comments controller with all the logic

app/controllers/comments_controller.rb
```ruby
class CommentsController < ApplicationController
  before_action :set_commentable

  def new
    @comment = Comment.new
  end

  def create
    @comment = @commentable.comments.build(comment_params)
    if @comment.save
      redirect_to @commentable unless @commentable.is_a?(Comment)
      redirect_to @commentable.find_top_parent if @commentable.is_a?(Comment)
      flash[:notice] = 'Comment created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      redirect_to @commentable unless @commentable.is_a?(Comment)
      redirect_to @commentable.find_top_parent if @commentable.is_a?(Comment)
      flash[:notice] = 'Comment deleted'
    else
      redirect_to @commentable, alert: 'Something went wrong'
    end
  end

  private

  # not very nice, in my opinion
  # def set_commentable
  #   if params[:inbox_id].present?
  #     @commentable = Inbox.find(params[:inbox_id])
  #   elsif params[:comment_id]
  #     @commentable = Comment.find(params[:comment_id])
  #   else
  #     "SOME ERROR"
  #   end
  # end

  def comment_params
    params.require(:comment).permit(:body).merge(user: current_user)
  end
end
```

* 2 controllers designed only to find a comment parent. No chance for `If-Else` mess.

controllers/inboxes/comments_controller.rb
```ruby
module Inboxes
  class CommentsController < CommentsController
    private

    def set_commentable
      @commentable = Inbox.find(params[:inbox_id])
    end
  end
end
```

app/controllers/comments/comments_controller.rb
```ruby
module Comments
  class CommentsController < CommentsController
    private

    def set_commentable
      @commentable = Comment.find(params[:comment_id])
    end
  end
end
```

* 5. Comment views

-> NEW

app/views/comments/new.html.erb
```ruby
New comment for
<%= link_to @commentable.name, @commentable unless @commentable.is_a?(Comment) %>
<%= link_to @commentable.find_top_parent.name, @commentable.find_top_parent if @commentable.is_a?(Comment) %>
<%= render 'comments/form', comment: @comment %>
```

-> FORM

app/views/comments/_form.html.erb
```ruby
<%= form_with(model: [@commentable, comment]) do |form| %>
  <%= render 'shared/errors', form: form %>

  <div class="field">
    <%= form.text_area :body,
      style: "width: 100%",
      maxlength: Comment::MAX_BODY_LENGTH, 
      placeholder: 'Add a comment here' %>
  </div>

  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```

-> SHOW

app/views/comments/_comment.html.erb
```ruby
<div class='comment'>
  <% if comment.deleted_at.present? %>
    <i>Comment has been deleted</i>
  <% else %>
    <%= comment.created_at %>
    by
    <%= link_to comment.user.name, comment.user %>
    <%= simple_format(comment.body) %>
    <%= button_to 'Delete', [@commentable, comment], method: :delete %>
  <% end %>
  comments:
  <%= comment.comments.count %>
  <%= link_to 'Reply', new_comment_comment_path(comment) %>
  <br>
  <%= render comment.comments %>
</div>
```

* 6. Render comment form and list in an inbox view

app/controllers/inboxes_controller.rb
```ruby
def show
  @commentable = @inbox
  @comment = Comment.new
  @comments = @inbox.comments
end
```

app/views/inboxes/show.html.erb
```ruby
<%= render template: 'comments/new' %>
<%= render @comments %>
```

* 7. Add some css

app/assets/stylesheets/application.css
```css
.comment {
  margin: 1em 0em 1em 1em;
  padding-left: 1em;
  border-left: 2px solid lightgray;
}
```