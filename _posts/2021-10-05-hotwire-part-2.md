---
layout: post
title: "Hotwire usecases. Part 2. Turbo stream inboxes to index"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

### 1. Turbo stream - new inboxes to inboxes index without refreshing the page

#app/models/inbox.rb
```ruby
class Inbox < ApplicationRecord
  has_many :messages, -> { order(created_at: :desc) }, dependent: :destroy

  validates :name, presence: true, uniqueness: true
 
  # add on top
  # after_create_commit {broadcast_prepend_to "inboxes"}

  # add on bottom
  # after_create_commit {broadcast_append_to "inboxes"}

  # after_destroy_commit { broadcast_remove_to "inboxes" }

  # after_update_commit { broadcast_update_to "inboxes" }

  # broadcast all activity (create, update, destroy)
  broadcasts_to ->(inbox) { :inboxes }
end
```

#app/views/inboxes/index.html.erb
```ruby
  <%= turbo_stream_from "inboxes" %>
  <div id="inboxes">
    <%= render @inboxes %>
  </div>
```

#console
```sh
Inbox.create(name: Faker::Lorem.sentence(word_count: 3))
Inbox.first.update(name: SecureRandom.hex)
Inbox.first.destroy
```

### 2. Turbo Frame - form to create inboxes in inboxes/index

#app/views/inboxes/index.html.erb
```ruby
<%= turbo_frame_tag 'inbox_form', src: new_inbox_path, loading: :lazy do %>
  Loading...
<% end %>
```

* go to show page that has a form partial, find the `turbo_frame_tag`

#app/views/inboxes/_form.html.erb
```ruby
<%= turbo_frame_tag 'inbox_form' do %>
  <%= form_with(model: inbox) do |form| %>
  <% end %>
<% end %>
```

* stream new frame to index page (to the current_user in this ActionCable:Broadcast connection)

#app/controllers/inboxes_controller.rb
```ruby
def create
  @inbox = Inbox.new(inbox_params)
  respond_to do |format|
    if @inbox.save
      format.turbo_stream { render turbo_stream: turbo_stream.replace(
        'inbox_form', 
        partial: 'inboxes/form', 
        locals: { inbox: Inbox.new }
      ) }
    end
  end
end
```
