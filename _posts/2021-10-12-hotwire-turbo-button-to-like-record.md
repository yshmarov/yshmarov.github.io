---
layout: post
title: "#6 Hotwire Turbo: Increment likes count without any page refreshes"
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

```ruby
#config/routes.rb
Rails.application.routes.draw do
  resources :inboxes do
    member do
      patch :like, to: 'inboxes#like'
    end
  end
end
```

* on event - replace the `_likes` partial
* include `include ActionView::RecordIdentifier` - to use `dom_id`
* create a unique dom id for this specific partial

```ruby
#app/controllers/inboxes_controller.rb
  include ActionView::RecordIdentifier

  def like
    @inbox = Inbox.find(params[:id])
    @inbox.increment!(:likes)
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

* keep it in a partial with a unique dom

```ruby
#app/views/inboxes/_likes.html.erb
<%= turbo_frame_tag "#{dom_id(inbox)}_likes" do %>
  <%= inbox.likes %>
<% end %>
```

* render the partial in the view
* add the button
* `data: { turbo_frame: '_top' }` - might be optional

```ruby
#app/views/inboxes/_inbox.html.erb
<div id="<%= dom_id inbox %>">
  <h1><%= link_to inbox.name, inbox %></h1>

  <%= render partial: 'inboxes/likes', locals: { inbox: inbox } %>
  <%= button_to 'Like!',
        like_inbox_path(inbox),
        method: :patch, data: { turbo_frame: '_top' } %>
</div>
```

* you might want to move the `Like!` button into the partial.
