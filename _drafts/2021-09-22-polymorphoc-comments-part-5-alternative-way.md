https://github.com/cjavdev/blog-demo/commit/73cccc3678bf40c0b6ab2f80996b25caae9b5fdb
https://www.youtube.com/watch?v=mtIBFvWZuwI

```
rails g model comments content:text post:belongs_to user:belongs_to parent:belongs_to
```
db/migrate/20210824234148_create_comments.rb
```
class CreateComments < ActiveRecord::Migration[6.1]
  def change
    create_table :comments do |t|
      t.text :content
      t.belongs_to :post, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :parent, null: true, foreign_key: true

      t.timestamps
    end
  end
end
```
app/models/comment.rb
```
class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user
  belongs_to :parent, class_name: 'Comment', optional: true
  has_many :comments, foreign_key: :parent_id
end
```
app/models/user.rb
```
  has_many :comments
```
app/models/post.rb
```
  has_many :comments
```
config/routes.rb
```
  resources :posts do
    resources :comments, only: [:create]
  end
```
app/controllers/comments_controller.rb
```
class CommentsController < ApplicationController
  def create
    @comment = current_user.comments.new(comment_params)
    if !@comment.save
      flash[:notice] = @comment.errors.full_messages.to_sentence
    end

    redirect_to post_path(params[:post_id])
  end

  private

  def comment_params
    params
      .require(:comment)
      .permit(:content, :parent_id)
      .merge(post_id: params[:post_id])
  end
end
```
app/views/posts/show.html.erb
```
<p>
  <strong>Comments:</strong>

  <%= render @post.comments.where(parent_id: nil).includes(:user, :post, comments: :user).order(id: :desc) %>
  <%= render partial: 'comments/form', locals: { post: @post, parent: nil } %>
</p>
```
app/views/comments/_form.html.erb
```
<form action="<%= post_comments_path(post) %>" method="post">
  <input type="hidden" name="authenticity_token" value="<%= form_authenticity_token %>">
  <% if !parent.nil? %>
    <input type="hidden" name="comment[parent_id]" value="<%= parent.id %>">
  <% end %>

  <div>
    <textarea name="comment[content]" rows="3" cols="20"></textarea>
  </div>

  <input type="submit" value="Submit">
</form>
```
app/views/comments/_comment.html.erb
```
<article>
  <p><%= comment.content %></p>
  <small>by <%= comment.user.email %></small>

  <a href="#" class="comment-form-display">reply</a>
  <div class="comment-form">
    <%= render partial: 'comments/form', locals: {post: comment.post, parent: comment} %>
  </div>

  <hr />
  <div class="sub-comment">
    <%= render comment.comments.includes(:user) %>
  </div>
</article>

 <script>
  document.querySelectorAll('.comment-form-display').forEach((el) => {
    el.addEventListener('click', (ev) => {
      ev.preventDefault();
      el.nextElementSibling.style = 'display: block;'
    })
  })
 </script>
```
app/assets/stylesheets/comments.scss
```
.sub-comment {
  padding-left: 20px;
}

.comment-form {
  display: none;
}
```