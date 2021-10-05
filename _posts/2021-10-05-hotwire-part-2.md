---
layout: post
title: "Hotwire usecases. Part 2"
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
 
  # add on bottom
  # after_create_commit {broadcast_append_to "inboxes"}

  # add on top
  # after_create_commit {broadcast_prepend_to "inboxes"}

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
