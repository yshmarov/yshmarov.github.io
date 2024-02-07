render :json => 

rails g scaffold Post title:string body:text published:boolean published_at:datetime

rails g controller api/v1/posts

rails g jbuilder api/v1/posts user:references title:string body:text --model-name=Post
rails g jbuilder api/v1/posts title:string body:text published:boolean published_at:datetime --model-name=Post

https://cloudolife.com/2020/08/29/Programming-Language/Ruby/Ruby-on-Rails-RoR/Use-rails-jbuilder-to-generate-JSON-objects-with-a-Builder-style-DSL/

https://guides.rubyonrails.org/action_view_overview.html#jbuilder

https://github.com/rails/jbuilder


render json: @user
render json: { message: 'User successfully update. '}, status:200
render json: { error: 'Unable to update user. '}, status:400

```ruby
# index.json.jbuider
json.articles @articles do |article|
  json.partial "article", obj: article
end
# _article.json.jbuilder
json.id obj.id
json.title obj.title
json.author do 
  json.user_id obj.user.id
  json.name obj.user.name
  json.slug @task.slug
  json.title @task.title
  json.assigned_user do
    json.id @task.assigned_user.id
    json.name @task.assigned_user.name
  end
end

json.microposts @microposts, partial: 'api/v1/microposts/micropost', as: :micropost

# app/views/messages/show.json.jbuilder

json.content format_content(@message.content)
# You can use the call syntax instead of an explicit extract! call:
json.extract! @message, :created_at, :updated_at
json.(@message, :created_at, :updated_at)

json.author do
  json.name @message.creator.name.familiar
  json.email_address @message.creator.email_address_with_name
  json.url url_for(@message.creator, format: :json)
end

if current_user.admin?
  json.visitors calculate_visitors(@message)
end

json.comments @message.comments, :content, :created_at

json.task do
  json.extract! @task,
    :id,
    :slug,
    :title
  json.assigned_user do
    json.extract! @task.assigned_user,
      :id,
      :name
  end
end

json.(obj, :id, :title) 
json.(obj.user, :id, :name) 
```

```ruby
  namespace :v1, defaults: { format: :json } do
  resources :tasks, except: %i[new edit], param: :slug, defaults: { format: 'json' }
  defaults format: :json do
    resources :tasks, except: %i[new edit], param: :slug
  end
```



