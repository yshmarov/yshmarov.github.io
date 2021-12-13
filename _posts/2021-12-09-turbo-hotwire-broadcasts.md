---
layout: post
title: "#17 Turbo Streams: Broadcasts"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo broadcasts
thumbnail: /assets/thumbnails/turbo.png
---

**Turbo Streams in Controller VS Broadcasts: When to use which?**

Rule of thumb:
* -> If you want to update the page when a user **INTERACTS** with it -> Streams in Controller
* -> If you want to send updates to a page **WITHOUT user interaction** -> Broadcasts

![Turbo Streams VS Broadcasts](/assets/images/stream-vs-broadcast.png)

Example behavior:
* Turbo Stream responce from **controller** - for current_user, when he does an action. Doesn't work in console.
* Turbo Stream responce from **model** (broadcast) - global updates in realtime. Works in console.

I would use broadcasts for:
* live chat
* "push" notification
* live dashboards

I would NOT use broadcasts for:
* user-triggered CRUD updates (like a post, add a comment, edit a record)

****

The common way to trigger [turbo broadcasts](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb#L39){:target="blank"} - with [ActiveRecordCallbacks](https://guides.rubyonrails.org/active_record_callbacks.html){:target="blank"} in a model.

Callbacks to use:
* `after_create_commit`
* `after_update_commit`
* `after_destroy_commit` (btw, `delete` doesn't fire a callback. `destroy` does)
* `after_save_commit`

[Turbo stream actions](https://turbo.hotwired.dev/reference/streams#the-seven-actions){:target="blank"}:
* `append` # add on bottom of DOM ID (`<div id="abc">`)
* `prepend` # add on top of DOM ID
* `replace` # replace a DOM ID (example: with an element with another id)
* `update` # update content INSIDE a DOM ID
* `remove` # no template required for this one!
* `before` # add **before** DOM ID (not inside it)!
* `after` # add **after** DOM ID (not inside it)!

****

### 1. Broadcast Create/Update/Destroy

* Initial setup:

```sh
rails g scaffold inbox name
rails db:migrate
bundle add faker
```

* Add a `turbo_stream_from` target with an ID anywhere on a page.

```diff
# app/views/inboxes/index.html.erb
++<%= turbo_stream_from "inbox_list" %>
  <div id="inboxes">
    <%= render @inboxes %>
  </div>
```

* This will "listen" to **broadcasts**, with a target `inbox_list`
* Now, when you navigate to a page that has `turbo_stream_from`, you will see something like this in the console:

![Turbo Broadcast listener](/assets/images/turbo-broadcast-listener.png)

* Next, add a **broadcasts**, with a target `inbox_list` in the model:

```diff
# app/models/inbox.rb
class Inbox < ApplicationRecord
  validates :name, presence: true, uniqueness: true
++broadcasts_to ->(inbox) { :inbox_list }
end
```

The above
* requires `<%= turbo_stream_from :inbox_list %>`
* a default target - `<div id="inboxes">`
* a default partial - `"inboxes/_inbox"`

* This will let you broadcast all activity (create, update, destroy).

* That's it! Now, you can try to create/update/destroy records in the console or in another tab:

```sh
Inbox.create(name: Faker::Quote.famous_last_words)
Inbox.first.update(name: "Edited at #{Time.zone.now}")
Inbox.first.destroy
```

* ... and changes will be "broadcasted" without page refresh:

![Turbo Broadcast CRUD](/assets/images/broadcast-create-destroy-update.gif)

### 2. `broadcasts_to` is too magical. Let's unbuild it!

* `broadcasts_to ->(inbox) { :inbox_list }` translates to:

```diff
# app/models/inbox.rb
--broadcasts_to ->(inbox) { :inbox_list }
++
++broadcasts_to ->(inbox) { :inbox_list }, inserts_by: :append, target: 'inboxes'
```

* or, more precisely

```diff
# app/models/inbox.rb
class Inbox < ApplicationRecord
--broadcasts_to ->(inbox) { :inbox_list }
--
--broadcasts_to ->(inbox) { :inbox_list }, inserts_by: :append, target: 'inboxes'
++
++after_create_commit { broadcast_append_to "inbox_list" }
++after_update_commit { broadcast_replace_to "inbox_list" }
++after_destroy_commit { broadcast_remove_to "inbox_list" }
++
++# after_create_commit { broadcast_prepend_to "inbox_list" } # would add on top
++# after_update_commit { broadcast_update_to "inbox_list" } # would add dom_id(inbox) inside dom_id(inbox)
end
```

* or, even more precisely:

```diff
# app/models/inbox.rb
class Inbox < ApplicationRecord
--broadcasts_to ->(inbox) { :inbox_list }
--
--broadcasts_to ->(inbox) { :inbox_list }, inserts_by: :append, target: 'inboxes'
--
--after_create_commit { broadcast_append_to "inbox_list" }
--after_update_commit { broadcast_replace_to "inbox_list" }
--after_destroy_commit { broadcast_remove_to "inbox_list" }
--
--# after_create_commit { broadcast_prepend_to "inbox_list" } # would add on top
--# after_update_commit { broadcast_update_to "inbox_list" } # would add dom_id(inbox) inside dom_id(inbox)
++
++after_create_commit do
++  broadcast_append_to('inbox_list', target: 'inboxes', partial: "inboxes/inbox", locals: { inbox: self })
++end
++
++after_update_commit do
++  broadcast_replace_to('inbox_list', target: self, partial: "inboxes/inbox", locals: { inbox: self })
++end
++
++after_destroy_commit do
++  broadcast_remove_to('inbox_list', target: self)
++end
end
```

So, in a turbo_stream you can specify:
* a `turbo_stream_from` **broadcast** (connection ID) to listen to
* a **target** - HTML element with an ID `DOM ID` (`<div id="abc">`) that gets replaced/updated/appended/destroyed... with a partial or HTML
* a **partial/html** to stream... for which you can set locals
* **locals** - local variables

*I recommend to use explicity paths. No shortcut magic!*

### 3. Broadcast `HTML`: Update inboxes count on create/destroy.

* add a `div id` in the view that will be updated by the broadcast.
* add a `turbo_stream_from`. You can use the same stream from above.

```ruby
# app/views/inboxes/index.html.erb
<%= turbo_stream_from "inbox_list" %>

<div id="inbox_count">
  <%= @inboxes.count %>
</div>
```

* send some HTML to the target `div id` when an inbox is created/destroyed
* set a matching turbo stream ID in the view and controller (`inbox_list`)

```ruby
# app/models/inbox.rb
  after_commit :send_html_counter, on: [ :create, :destroy ]
  def send_html_counter
    broadcast_update_to('inbox_list', target: 'inbox_count', html: "There are #{Inbox.count} inboxes")
    # broadcast_update_to('inbox_list', target: 'inbox_count', html: Inbox.count)
  end
```

Now, you can create/destroy a record in the `rails console` and the counter will be updated!

### 4. Broadcast `Partial`: Update inboxes count on create/destroy.

* create the partial:

```ruby
# app/views/inboxes/_inbox_count.html.erb
Total inboxes:
<%= inbox_q %>
```

* display it in a view:

```ruby
# app/views/inboxes/index.html.erb
<%= turbo_stream_from "inbox_list" %>

<div id="inbox_count">
  <%= render partial: "inboxes/inbox_count", locals: {inbox_q: Inbox.count} %>
</div>
```

* add a broadcast to update the content within `<div id="inbox_count">`

```ruby
# app/models/inbox.rb
  after_commit :send_partial_counter, on: [ :create, :destroy ]
  def send_partial_counter
    broadcast_update_to('inbox_list', target: 'inbox_count', partial: "inboxes/inbox_count", locals: { inbox_q: Inbox.count })
  end
```

Surely, you can also send a partial without locals ;)

### 5. Error broadcasting `button_to`

Before `rails 7.0.0rc` you might have a CSFR error when streaming `button_to`:

```sh
`ensure_session_is_enabled!': Request forgery protection requires a working session store but your application has sessions disabled. You need to either disable request forgery protection, or configure a working session store. (ActionController::RequestForgeryProtection::DisabledSessionError)
```

For example, in a case like this:

```diff
# app/views/inboxes/_inbox.html.erb

<div id="<%= dom_id inbox %>">
  <%= inbox.id %>
  <%= inbox.name %>
++<%= button_to "Destroy this inbox", inbox_path(inbox), method: :delete %>

</div>
```

It can be fixed by adding:

```diff
# config/application.rb
++ config.action_controller.silence_disabled_session_errors = true
```

### 6. Broadcasting [ViewComponent](https://viewcomponent.org){:target="blank"}

Previously I wrote about [(4 ways to Turbo Stream ViewComponent)]({% post_url 2021-11-05-turbo-stream-view-components %}). They won't work from a model.

However, there is a way:

* Install ViewComponent
* Create a component

```sh
bundle add view_component
rails g component inbox inbox
```

```ruby
# app/components/inbox_component.html.erb
<div id="<%= dom_id inbox %>">
  <%= inbox.name %>
  <%= link_to "Show this inbox", inbox %>
  <%= link_to "Edit this inbox", edit_inbox_path(inbox) %>
  <%= button_to "Destroy this inbox", inbox_path(inbox), method: :delete %>
</div>
```

* add `attr_reader :inbox` to be able to access `inbox` without `@inbox`

```ruby
# app/components/inbox_component.rb
class InboxComponent < ViewComponent::Base
  attr_reader :inbox
  def initialize(inbox:)
    @inbox = inbox
  end
end
```

* now you can render a single inbox or a [collection](https://viewcomponent.org/guide/collections.html){:target="blank"} like this:

```
<%= render(InboxComponent.with_collection(@inboxes)) %>
<%= render InboxComponent.new(inbox: Inbox.first) %>
```

* so, render the component(s) in the view:

```ruby
# app/views/inboxes/_inbox.html.erb
<%= turbo_stream_from "inbox_list" %>

<div id="inboxes">
  <%= render(InboxComponent.with_collection(@inboxes)) %>
  <%#= render @inboxes %>
</div>
```

* and broadcast them in the model LIKE THIS

```ruby
# app/models/inbox.rb
  after_create_commit do
    # these will not render the HTML
    # InboxComponent.new(inbox: self)
    # render_to_string(InboxComponent.new(inbox: self))
    # view_context.render(InboxComponent.new(inbox: self))
    # InboxComponent.new(inbox: self).render_in(view_context)

    # this will:
    broadcast_append_to('inbox_list', target: 'inboxes', html: ApplicationController.render(InboxComponent.new(inbox: self)))
  end
```

### 7. Broadcasting associations

* Add `messages` to `inboxes`

```sh
rails g scaffold message body:text inbox:references
```

```ruby
# app/models/inbox.rb
  has_many :messages
```

```ruby
# app/models/message.rb
  belongs_to :inbox
```

* render messsages inside an inbox
* add a `turbo_stream_from` target that is UNIQUE for this inbox

```ruby
# app/views/inboxes/show.html.erb
<%= render @inbox %>
<%= turbo_stream_from @inbox, :messages %>
<div id="<%= dom_id(@inbox, :messages) %>">
  <%= render @inbox.messages %>
</div>
```

* Now, broadcast messages into an inbox
* `[inbox, :messages]` will stream to `dom_id(@inbox, :messages)`

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :inbox

  # lets you use dom_id in a model
  include ActionView::RecordIdentifier

  after_create_commit do 
    broadcast_prepend_to [inbox, :messages], target: dom_id(inbox, :messages), partial: "messages/message", locals: { message: self }
    # broadcast_prepend_to [inbox, :messages], target: ActionView::RecordIdentifier.dom_id(inbox, :messages)
  end

  after_destroy_commit do
    broadcast_update_to [inbox, :messages], target: self, partial: "messages/message", locals: { message: self }
  end

  after_update_commit do
    broadcast_update_to [inbox, :messages], target: self
  end
end
```

* Now you can add messages to an inbox and they will be broadcasted into the inbox!

```
Inbox.first.messages.create body: SecureRandom.hex
Inbox.first.messages.last.update body: "hello world"
Inbox.first.messages.last.destroy
```

### P.S. WTF `dom_id`?!

Here's how [ActionView::RecordIdentifier](https://api.rubyonrails.org/v4.2.5/classes/ActionView/RecordIdentifier.html) `dom_id` works:

```ruby
# dom_id(Inbox.first)
# => inbox_1

# dom_id(Inbox.first, :hello)
# => hello_inbox_1
```

That's it!

Next, I hope to explore Broadcasts + Devise + Authorization