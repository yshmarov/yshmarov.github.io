---
layout: post
title: "Hotwire Turbo: Increment likes count without any page refreshes"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

### In this case we will replace a `_likes` partial inside `_inbox` partial, not the whole `_inbox` partial.

![turbo-frame-replace-button](/assets/images/turbo-like-without-refresh.gif)
**EVERYTHING IS PERSISTED IN THE DATABASE.**

* console

```sh
rails g migration add_likes_to_inboxes like:integer
```

* the migration

```ruby
    add_column :inboxes, :likes, :integer, default: 0, null: false

```

* add the route

#config/routes.rb
```ruby
Rails.application.routes.draw do
  resources :inboxes do
    member do
      patch :like, to: 'inboxes#like'
    end
  end
end
```

* keep it in a partial with a unique dom

#app/views/inboxes/_likes.html.erb
```ruby
<%= turbo_frame_tag "#{dom_id(inbox)}_likes" do %>
  <%= inbox.likes %>
<% end %>
```

* render the partial in the view
* add the button

#app/views/inboxes/_inbox.html.erb
```ruby
<div id="<%= dom_id inbox %>">
  <h1>
    <%= link_to inbox.name, inbox, data: { turbo_frame: '_top' } %>
  </h1>
  <%= render partial: 'inboxes/likes', locals: { inbox: inbox } %>
  <%= button_to 'Like!',
        like_inbox_path(inbox),
        method: :patch, data: { turbo_frame: '_top' } %>
</div>
```

* on event - replace the `_likes` partial

#app/controllers/inboxes_controller.rb
```ruby
  include ActionView::RecordIdentifier

  def like
    @inbox = Inbox.find(params[:id])
    @inbox.like!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "#{dom_id(@inbox)}_likes",
          partial: 'inboxes/likes',
          locals: { inbox: @inbox }
        )
      end
    end
  end
```
