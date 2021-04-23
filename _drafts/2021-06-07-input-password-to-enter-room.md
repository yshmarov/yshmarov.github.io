

posts_controller.rb
```
  def password
    post = Post.find_by(id: params[:post_id])
    if post.present?
      redirect_to post_path(post), notice: "Success"
    else
      redirect_to posts_path, alert: "Failure"
    end
  end
```

routes.rb
```
  resources :posts do
    get :password, on: :collection
  end
```

any view
```
<%= form_tag password_posts_path, method: :get do %>
  <%= text_field_tag "post_id" %>
  <%= submit_tag "GO" %>
<% end %>
```

