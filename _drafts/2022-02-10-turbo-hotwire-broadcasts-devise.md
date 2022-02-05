---
layout: post
title: "#23 Turbo Streams: Broadcasts with Devise and Authorization"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo broadcasts devise pundit authorization
thumbnail: /assets/thumbnails/turbo.png
---

### Devise: broadcast to a specific user

* broadcast to a specific user (not everybody)
* broadcast to current_user

Example: send User-specific notifications

  <%= turbo_stream_from(current_user) if user_signed_in? %>

### Devise: broadcast based on user authorization

* broadcast based on `current_user` roles/authorization

The below is partially inspired by [Cloud66: Making Hotwire and Devise play nicely](https://blog.cloud66.com/making-hotwire-and-devise-play-nicely-with-viewcomponents/)

* Initial setup: `Post` belongs to `User`

```sh
rails c
Post.delete_all
exit
rails g migration add_user_to_posts user:references
rails db:migrate
```

```diff
# app/models/post.rb
++ belongs_to :user
```

* do not broadcast anything with current_user. Use LOCAL VARIABLES

```diff
# app/views/posts/index.html.erb
<div id="posts">
--  <%= render @posts %>
++  <%= render partial: "posts/post", collection: @posts, locals: { user: current_user } %>
</div>
```

```diff
# app/views/posts/show.html.erb
x--  <%= render @post %>
++  <%= render partial: "posts/post", locals: {post: @post, user: current_user} %>
```

```diff
# app/views/posts/_post.html.erb
<div id="<%= dom_id post %>">
  <%= post.id %>
  <%= post.title %>

--  <%= link_to "Edit this post", edit_post_path(post) %>
--  <%= button_to "Destroy this post", post_path(post), method: :delete %>
++  <%= link_to "Edit this post", edit_post_path(post) if post.user == user %>
++  <%= button_to "Destroy this post", post_path(post), method: :delete if post.user == user %>

++  <%= post.user.email %>
</div>
```

The trick is just in passing current_user into the model.

You could pass the current user as a local variable from the controller into the model:

```diff
# app/controllers/posts_controller.rb
  def create
    @post = current_user.posts.new(post_params)
      if @post.save
++        @post.send_on_create(current_user)
        redirect_to @post
    end
  end
```

And than have a model action that would broadcast:

```diff
# app/models/post.rb

++  # this way it is triggered in the controller -> is not a callback action; can not be accessed via console either. 
++  def send_on_create(creator)
++    broadcast_append_to('posts_list', target: 'posts', partial: "posts/post", locals: { post: self, user: creator })
++  end

  after_create_commit do
--    broadcast_append_to('posts_list', target: 'posts', partial: "posts/post", locals: { post: self })
++    broadcast_append_to('posts_list', target: 'posts', partial: "posts/post", locals: { post: self, user: current_user })
++    # after_update_commit -> { current_user ? broadcast_append_to(self, locals: { user: current_user, post: self }) : nil }
  end
```

### Broadcast directly from controller

```ruby
format.turbo_stream {
  Turbo::StreamsChannel.broadcast_replace_later_to @message.room, current_user
    target: @message,
    partial: "messages/message",
    locals: { message: @message, current_user: current_user }
}
```

****

Access a current_user in console [(source: twitter)](https://twitter.com/websebdev/status/1451897969276604424)

```ruby
# Add this in any initializer or environment
# like config/environments/development.rb
module Rails: :ConsoleMethods
  # This method will be available in the
  # development Rails console
  def login
    Current.user = User.first
  end
end
```

### Useful tips:

1. It is better to use `broadcast_action_later_to` than `broadcast_action_to`

2. to use dom_id in a **model**, you need to include it:
* `include ActionView::RecordIdentifier` - in the whole model
* `ActionView::RecordIdentifier.dom_id(@inbox)` - only in a specific place

3. `Prepend` = TOP. `Append` = BOTTOM. 

4. `Replace` VS `Update` ? YARO

****

<%= Inbox.count %>
<hr>
<% Inbox.group_by_day(:created_at).count.each do |day, q| %>
<%#= Inbox.all.max_by(&:messages_count) %>

<label for="fuel">
  <%= day.strftime("%d %b") %>
</label>

<meter id="fuel"
       min="0" max="<%= Inbox.group_by_day(:created_at).count.max_by{|k,v| v}.last %>"
       low="33" high="66" optimum="80"
       value="<%= q %>">
</meter>
<br>
<% end %>

### frames search URL

replace - replace current url in browser history
advance - move forward in browser history

<%= form_with url: customers_path, method: :get, data: { turbo_frame: "customers", turbo_action: "advance" } do |form| %>
  <%# Some form content goes here %>
<% end %>

### CONFIRMATION

<%= link_to "Delete", project_path(project),
  "data-turbo-method": :delete,
  "data-turbo-confirm": "Are you sure?" %>

###

https://blog.cloud66.com/hotwire-viewcomponents-and-tailwindcss-the-ultimate-rails-stack/



****
  after_create_commit :append_new_record

  private

  def append_new_record
    broadcast_append_to(
      'spies',
      html: ApplicationController.render(
        SpyComponent.new(spy: self)
      )
    )
  end






after_create_commit { broadcast_append_to self.room }
