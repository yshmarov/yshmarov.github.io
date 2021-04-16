---
layout: post
title: "Telegram Part 3. Authentication. Bot to send private messages"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails telegram bots httparty
thumbnail: /assets/thumbnails/telegram.png
---

### TODO: 
1. User logs in with telergam & permits bot to send private messages. 
2. We get user telegram_id and save it in database.
3. Send CRUD notifications to user via telegram.

prerequisites:
* [Telegram Part 1]({% post_url 2021-03-22-ruby-on-rails-telegram-api-send-message %}){:target="blank"}
* [Telegram Part 2]({% post_url 2021-04-12-ruby-on-rails-telegram-notifications %}){:target="blank"}

### 1. Button to log in with telegram

Create a widget:
[https://core.telegram.org/widgets/login](https://core.telegram.org/widgets/login){:target="blank"}

Example result that can be added to any view:
```
<script async 
  src="https://telegram.org/js/telegram-widget.js?14" 
  data-telegram-login="gorocrm_bot" 
  data-size="small"
  data-userpic="false"
  data-auth-url="https://localhost:3000/"
  data-request-access="write">
</script>
```
after pressing the button and authenticating with telergam, the user will be redirected to the `data-auth-url`

with the following params
```
https://localhost:3000/?id=123456&first_name=Yaro&last_name=Shm&username=yarotheslav&auth_date=1613682858&hash=fa242eca
```
these params can be accessed in the redirect view `.html.erb` file by adding:
```
<%= params[:id] %>
<%= params[:first_name] %>
<%= params[:last_name] %>
<%= params[:username] %>
```
At this point the user is authenticated, and our bot is allowed to send him private messages.

### 2. Save telegram_id for current_user

Now we want to save the users telegram id to the database to be able to send him chat messages.

For this we will: 
1. after successfull telegram authentication redirect user to a controller action
2. controller action will save the `params[:id]` to `current_user.telegram_id`
3. redirect to `user_path(current_user)`

console - add `telegram_id` to `users` table
```
rails g migration add_telegram_id_to_users telegram_id:integer
```

Change the telegram `data-auth-url` to redirect to a controller action.

Example 1: to `users_path(current_user)`
```
data-auth-url="<%= url_for(controller: "users", action: 'show', id: current_user.id) %>" 
```
Example 2 (our way): to `telegram_controller.rb`, action `telegram_auth`
```
data-auth-url="<%= url_for(controller: "telegram", action: 'telegram_auth') %>" 
```
telegram_controller.rb save the telegram_id and redirect
```
class TelegramController < ApplicationController
  def telegram_auth
    if params[:id].present?
      current_user.update(telegram_id: params[:id])
    end
    redirect_to user_path(current_user), notice: "Telegram authentication: success"
  end
end
```
routes.rb
```
  get "telegram_auth", to: "telegram#telegram_auth"
  post "telegram_auth", to: "telegram#telegram_auth"
```
now in users/show.html.erb you can access the `user.telegram_id`
```
<%= @user.telegram_id %>
```

### 3. Send private message to user on CRUD action if user has a telegram_id

app/controllers/posts_controller.rb - add a new `TelegramMailer` that specifies a `user`
```
def create
  @post = Post.new(post_params)
  if @post.save
    text = "#{current_user} created post: #{@post.title}"
    TelegramMailer.private_message(text, current_user).deliver_now
    redirect_to @post, notice: 'Post was successfully created.'
  else
    render :new
  end
end
```

app/mailers/telegram_mailer.rb - action for bot to send message to the user
```
def private_message(text, user)
  api_secret_key = "1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM"
  chat_id = user.telegram_id

  HTTParty.post("https://api.telegram.org/bot#{api_secret_key}/sendMessage",
    headers: {
      'Content-Type' => 'application/json'
    },
    body: {
      chat_id: chat_id,
      text: text
    }.to_json
  )
end
```

### 4. Next steps

* app with telegram-only log in
* check if telegram authentication hash is valid
* telegram communication bot
