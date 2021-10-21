---
layout: post
title: "#5 Turbo: Button to update status and refresh frame. Edit inboxes inline"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

### IMPORTANT NOTICE before start!

There's currently some problem turbo_streaming `button_to` (for example `Delete`):

`sh
[ActiveJob] [Turbo::Streams::ActionBroadcastJob] [b1e06c35-6ac8-4a34-b717-41236ebcc593] Error performing Turbo::Streams::ActionBroadcastJob (Job ID: b1e06c35-6ac8-4a34-b717-41236ebcc593) from Async(default) in 44.89ms: ActionView::Template::Error (Request forgery protection requires a working session store but your application has sessions disabled. You need to either disable request forgery protection, or configure a working session store.):
`

![button-to-turbo-stream-error](/assets/images/button-to-turbo-stream-error.png)

To fix this, add this line:

#config/application.rb
```ruby
    config.action_controller.silence_disabled_session_errors = true
```

****

### 3.1. Button to update & replace frame

![turbo-frame-replace-button](/assets/images/turbo-frame-replace-button.gif)
**EVERYTHING IS PERSISTED IN THE DATABASE.**

* basic setup

```ruby
rails g migration add_active_to_inboxes active:boolean
```

* migration:

```ruby
    add_column :inboxes, :active, :boolean, default: 0, null: false
```

* helpers for active state

inbox.rb
```ruby
  # ideally should be moved to a decorator or a helper
  def active_color
    if active?
      :green
    else
      :red
    end
  end

  def active_text
    active? ? 'deactivate!' : 'activate!'
  end
```

* route to toggle active state

#config/routes.rb

```ruby
  resources :inboxes do
    resources :messages, only: %i[new create destroy], module: :inboxes
    member do
      patch :toggle_active_state, to: 'inboxes#toggle_active_state'
    end
  end
```

* add the controller action
* respond with turbo! find the turbo frame and replace it with `turbo_stream.replace`
* In this case we will replace the whole `_inbox` partial.

#app/controllers/inboxes_controller.rb
```ruby
  # to get dom_id
  include ActionView::RecordIdentifier

  def toggle_active_state
    @inbox = Inbox.find(params[:id])
    @inbox.toggle!(:active)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@inbox),
          partial: 'inboxes/inbox',
          locals: { inbox: @inbox }
        )
      end
    end
  end
```

* add status_color style
* add a classic button to the controller action
* add turbo frame _top to links that should target away from the frame

#app/views/inboxes/_inbox.html.erb
```ruby
<%= turbo_frame_tag dom_id(inbox), style: "background: <%= inbox.active_color %>" do %>
  <%= inbox.active %>
  <%= button_to inbox.active_text,
        toggle_active_state_inbox_path(inbox),
        method: :patch, data: { turbo_frame: '_top' } %>
    <%= link_to inbox.name, inbox, data: { turbo_frame: '_top' } %>
  <%= link_to "Edit", edit_inbox_path(inbox) %>
<% end %>
```

### 2. Edit an inbox

* the above `link_to "Edit"` will find the frame in EDIT page

#app/views/inboxes/edit.html.erb
```ruby
<%= turbo_frame_tag dom_id(@inbox) do %>
  <%= render "form", inbox: @inbox %>
  <%= link_to "Cancel", @inbox %>
<% end %>
```
