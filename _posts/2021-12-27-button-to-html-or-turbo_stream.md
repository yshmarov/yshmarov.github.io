---
layout: post
title: "#18 BUTTON_TO: conditionally respond with html OR turbo_stream"
author: Yaroslav Shmarov
tags: ruby-on-rails-7 hotwire turbo button_to
thumbnail: /assets/thumbnails/turbo.png
---

Sometimes you want the same action to respond to different formats.

For example:
* button1 - upvote WITH page refresh;
* button2 - upvote WITHOUT page refresh.

So, in one case:
* button1 - usual HTML responce;
* button2 - TURBO_STREAM responce.

We will have to:
* make the controller action respond to different formats
* button1 and button2 should trigger different formats

Examples:

button1 - upvote and redirect (HTML):

![button1 - upvote and redirect](assets/images/html-upvote.gif)

button2 - upvote without redirect (TURBO):

![button2 - upvote without redirect](assets/images/turbo-upvote.gif)

### 0. Initial setup. Upvote messages (format HTML).

```ruby
rails g scaffold message body:text likes_count:integer
```

It's good to add some defaults:
* `default: 0, null: false` to `likes_count`

So the migration will look like this:

```ruby
# db/migrate/20211225112627_create_messages.rb
class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.text :body
      t.text :likes_count, default: 0, null: false

      t.timestamps
    end
  end
end
```

* upvote route

```ruby
# app/config/routes.rb
  resources :messages do
    member do
      put :upvote
    end
  end
```

* upvote action

```ruby
# app/controllers/messages_controller.rb
  def upvote
    @message = Message.find(params[:id])
    @message.increment!(:likes_count)
    redirect_to messages_url, notice: "Upvoted #{@message.id}"
  end
```

* upvote button

```ruby
# app/views/messages/_message.html.erb
  <%= message.likes_count %>
  <%= button_to "Upvote HTML", upvote_message_path(message), method: :put %>
```

So now we have a button that will upvote and redirect!

### 1.1. respond to format with `button_to`

Now we want to do the same, but without page refresh.

Turbo Streams to the rescue!

* add `format.turbo_stream` in the controller:
* we need `ActionView::RecordIdentifier` to make `dom_id` work in a controller

```ruby
# app/controllers/messages_controller.rb
  def upvote
    @message = Message.find(params[:id])
    @message.increment!(:likes_count)
    respond_to do |format|
      format.html do
        redirect_to messages_url, notice: "Works #{@message.id}"
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(ActionView::RecordIdentifier.dom_id(@message, :likes), html: "#{@message.likes_count} #{Time.zone.now}")
      end
    end
  end
```

* add a `dom_id` that will be updated by the above turbo_stream responce:

```ruby
# app/views/messages/_message.html.erb
  <div id="<%= dom_id(message, :likes) %>">
    <%= message.likes_count %>
  </div>
```

BUT now if you click the `button_to` from above, it will respond with format turbo_stream by default!

So if you don't specify a format, it will try turbo_stream (not HTML) by default.

### 1.2. Different buttons to respond to different formats:

Good practice - explicitly state the format that you want to respond to.

* explicitly respond with HTML:
```ruby
# app/views/messages/_message.html.erb
<%= button_to "Upvote and redirect", upvote_message_path(message, format: :html), method: :put %>
```

* respond with TURBO_STREAM:
```ruby
# app/views/messages/_message.html.erb
<%= button_to "Upvote without redirect", upvote_message_path(message), method: :put, form: {"data-type": "turbo_stream" } %>
```

### 1.3. Classic `link_to` method?

Since `rails-ujs` is depreciated and its' functionality is take over by `turbo-rails`.

Now, you are supposed to use:
* `link_to` - for `get` requests;
* `button_to` - for `post`, `patch`, `put`, and `delete` requests.

However if you do want to have `link_to` another method, you can use 
[`data-turbo-method`](https://turbo.hotwired.dev/handbook/drive#performing-visits-with-a-different-method){:target="blank"}:
```diff
--<%= link_to "link html", upvote_message_path(post) %>
++<%= link_to "link_to turob_stream1", upvote_message_path(message), 'data-turbo-method': :patch %>
++<%= link_to "link_to turob_stream2", upvote_message_path(message), data: {turbo_method: "patch"} %>
```

****

**IMPORTANT**: the below DOES NOT WORK:
```ruby
# app/views/messages/_message.html.erb
<%= button_to "Upvote without redirect (broken)", upvote_message_path(message, format: :turbo_stream), method: :put %>
<%= button_to "Upvote and redirect (broken)", upvote_message_path(message), method: :put, :form => {"data-type" => "html" } %>
```

That's it! Now you can have 2 "upvote" buttons that will respond to either `HTML` or `TURBO_STREAM` format!

**Homework**: have a look at the HTML that is generated by each of these buttons. See the difference?
