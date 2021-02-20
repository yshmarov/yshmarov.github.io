---
layout: post
title: "Telegram Part 1. Button to send group messages"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails telegram bots httparty
thumbnail: /assets/thumbnails/telegram.png
---

### TODO: Telegram bot that sends messages to a telegram group when an event in your Rails app happens
![telegram-rails-gif.gif](/assets/ruby-on-rails-telegram-bot/telegram-rails-gif.gif)

****

### Step 1. Telegram Setup. API calls via the browser
create a telegram bot:
![botfather.png](/assets/ruby-on-rails-telegram-bot/botfather.png)
save the API key that you were given to access the app:
```
bot1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM
```
Next - create a telegram group, invite the bot bot to group, make the bot a group admin

Next - get the group id via an API call in the browser:
```
https://api.telegram.org/bot1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM/getUpdates
```
result:
![groupid.png](/assets/ruby-on-rails-telegram-bot/groupid.png)
from the request we will see the group id:
```
-574253305
```
Now we can post a message to the group via the browser:
```
https://api.telegram.org/bot1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM/sendMessage?chat_id=-574253305&text=yo
```
result:
![tgresult.png](/assets/ruby-on-rails-telegram-bot/tgresult.png)
### Step 2. Rails link_to post a bot message - view (elementary)
any view:
```
<%= link_to "Send message via View", "https://api.telegram.org/bot1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM/sendMessage?chat_id=-574253305&text=yo", method: :post %>
```
### Step 3. Rails link_to post a bot message - controller (advanced)
We will need to send HTTP requests from a controller action. 
For this we will use `gem "httparty"`.

gemfile
```
gem "httparty", "~> 0.18" # Makes http fun! Also, makes consuming restful web services dead easy
```
routes.rb
```
post "bots/say_hello", to: "bots#say_hello", as: :say_hello
```
bots_controller.rb - displays a few different ways of sending an HTTParty requests.
```
class BotsController < ApplicationController

  def say_hello
    # https://api.telegram.org/bot1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM/getUpdates
    api_secret_key = "1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM"
    chat_id = "-574253305"

    text = "#{current_user} @yarotheslav #{request.url} sorry for spam"

    # HTTParty.post("https://api.telegram.org/bot#{api_secret_key}/sendMessage?chat_id=#{chat_id}&text=#{text}")
    # HTTParty.post('https://api.telegram.org/bot1629298034:AAGMejWo9WFeZ-XP51f4Tpbb_L_0t8nO4xM/sendMessage?chat_id=-574253305&text=yo%20bro')
    # HTTParty.post("https://api.telegram.org/bot#{api_secret_key}/sendMessage?chat_id=#{chat_id}&text=#{text}")
    
    # body = {text: "#{current_user} is alive", chat_id: chat_id}
    # HTTParty.post("https://api.telegram.org/bot#{api_secret_key}/sendMessage", body: body)

    HTTParty.post("https://api.telegram.org/bot#{api_secret_key}/sendMessage",
      headers: {
        'Content-Type' => 'application/json'
      },
      body: {
        chat_id: chat_id,
        text: text
      }.to_json
    )
    redirect_to root_path, notice: "message sent"
  end

end
```
any view - invoke this controller action:
```
<%= link_to "Send message via Controller", say_hello_path, method: :post %>
```
or a button that has `method: :post` included by default:
```
<%= button_to "Send message via Controller", say_hello_path %>
```

Useful links & future readings:

* [https://github.com/jnunemaker/httparty](https://github.com/jnunemaker/httparty){:target="blank"}
* [https://core.telegram.org/bots/api](https://core.telegram.org/bots/api){:target="blank"}
* [https://www.sitepoint.com/quickly-create-a-telegram-bot-in-ruby/](https://www.sitepoint.com/quickly-create-a-telegram-bot-in-ruby/){:target="blank"}
* [https://github.com/atipugin/telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby){:target="blank"}
