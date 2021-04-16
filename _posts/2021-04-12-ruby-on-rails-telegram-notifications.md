---
layout: post
title: "Telegram Part 2. Notification for CRUD actions"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails telegram bots httparty
thumbnail: /assets/thumbnails/telegram.png
---

### TODO: Telegram bot notifies group chat whenever a new post is created.

prerequisites:
* [Telegram Part 1]({% post_url 2021-03-22-ruby-on-rails-telegram-api-send-message %}){:target="blank"}

console:
```
rails g mailer TelegramMailer
```
app/mailers/telegram_mailer.rb - action for bot to send message to the chat
```
class TelegramMailer < ApplicationMailer
  def group_message(text)
    api_secret_key = "1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM"
    chat_id = "-574253305"

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
end
```
`api_secret_key` - access key of the bot. 

`chat_id` - ID of the group chat.

app/controllers/posts_controller.rb
```
def create
  @post = Post.new(post_params)
  if @post.save
    text = "#{current_user} created post: #{@post.title}"
    TelegramMailer.group_message(text).deliver_now
    redirect_to @post, notice: 'Post was successfully created.'
  else
    render :new
  end
end
```

`text` - customizable text that will be send via telegram.

`TelegramMailer.group_message(text).deliver_now` - action to send the message from `telegram_mailer.rb`

### That's it!
