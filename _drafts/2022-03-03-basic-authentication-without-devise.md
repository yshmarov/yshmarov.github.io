VERY Basic authentication without Devise


```ruby
rails g model User username
rails db:migrate
```

#app/controllers/application_controller.rb
```ruby
helper_method :current_user

def current_user
  if session[:user_id]
    @current_user  = User.find(session[:user_id])
  end
end

def log_in(user)
  session[:user_id] = user.id
  @current_user = user
  redirect_to root_path
end

def logged_in?
  !current_user.nil?
end

def log_out
  session.delete(:user_id)
  @current_user = nil
end
```

#app/controllers/sessions_controller.rb
```ruby
class SessionsController < ApplicationController

  def create
    user = User.find_by(username: params[:session][:username])
    if user
      log_in(user)
    else
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_path
  end

end
```

#app/views/sessions/new.html.erb
```ruby
<%= form_for (:session) do |f| %>
  <%= f.label :username, 'Enter your username' %>
  <%= f.text_field :username, autocomplete: 'off' %>
  <%= f.submit 'Sign in' %>
<% end %>

```

#routes.rb
```ruby
Rails.application.routes.draw do
  get '/signin', to: 'sessions#new'
  post '/signin', to: 'sessions#create'
  delete '/signout', to: 'sessions#destroy'
end
```

#app/controllers/application_controller.rb
```ruby
	before_action :authenticate_user!

	private

	def authenticate_user
    redirect_to '/signin' unless @current_user
  end
```

<%= link_to 'Sign Out', signout_path,  :method => :delete %>
