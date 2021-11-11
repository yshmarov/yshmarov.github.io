### Conditionally resond with turbo or html?


turbo-hotwire-CRUD-broadcasts
### +7. VIA MODEL: Update inboxes count on create/destroy.

* you can target a dom id (any html element that has an ID set) Not turbo frame needed for the stream to work.

* Turbo Stream responce from controller - for current_user, when he does an action. doesn't work in console.
* Turbo stream responce from model (broadcast) - global updates in realtime. works in console.

* Please, use explicity paths. No shortcut magic:

```ruby
#app/models/inbox.rb
  after_commit :send_counter, on: [ :create, :destroy ]
  def send_counter
    # broadcast_action_later_to > broadcast_action_to

    # 1. broadcast - connection ID
    # 2. target gets replaced/updated/appended....
    # 3. partial...

    # <%= turbo_stream_from "inboxes" %> creates broadcast named inboxes
    # broadcast_append_to('inboxes')
    # default target - inboxes
    # default partial - _inbox
    # override target:
    # broadcast_append_to('inboxes', target: 'inboxes_list') }
    # override partial:
    # after_create_commit { broadcast_append_to('inboxes', partial: 'something_new') }
    # override breadcast target: <%= turbo_stream_from "inbox_broad" %>
    # after_create_commit { broadcast_append_to('inbox_broad', target: 'inboxes_list', partial: 'something_new') }
    broadcast_update_to('inbox_quantity', target: "inbox_target", partial: 'inboxes/inbox_count')
  end
```

* set a matching turbo stream ID in the view
* set a target where the partial should go

```ruby
<%= turbo_stream_from 'inbox_quantity' %>
<div id="inbox_target"></div>
```

* create the partial:

```ruby
#app/views/inboxes/_inbox_count.html.erb
<div style="background: orange;">
	Total inboxes:
	<%= Inbox.count %>
	<br>
	New inbox id:
	<%= inbox.id %>
</div>
```


### 2. VIA MODEL: Stream a created inbox to inboxes list

There are many ways to set up broadcasting.

Turbo stream actions:
* `append`
* `prepend`
* `replace`
* `update`
* `remove`
* `before`
* `after`

Callbacks to use from model:
* `after_update_commit`
* `after_create_commit`
* `after_destroy_commit` (`delete` doesn't fire a callback. `destroy` does)
* `after_save_commit`

In a turbo_stream you can specify:
* a `turbo_stream_from` broadcast to listen to
* an HTML element with an ID `DOM ID` (`<div id="abc">`)
* a partial to stream (or just some HTML)
* locals for the partial

****

2.1. add a target anywhere on the index page
* by default it will target dom with id "inboxes", but you can also overwrite it

```diff
#app/views/inboxes/index.html.erb
++ <%= turbo_stream_from :inbox_list %>
<div id="inbox_list">
  <%= render @inboxes %>
</div>
```

```ruby
#app/models/inbox.rb
  # add on top
  # after_create_commit {broadcast_prepend_to "inboxes"}

  # add on bottom
  # after_create_commit {broadcast_append_to "inboxes"}

  # after_destroy_commit { broadcast_remove_to "inboxes" }

  # after_update_commit { broadcast_update_to "inboxes" }

  # broadcast all activity (create, update, destroy)
  # broadcasts_to ->(inbox) { :inboxes }

  # broadcasts_to ->(inbox) { :inbox_list }
  # requires a <%= turbo_stream_from :inbox_list %>
  # requires a <div id="inboxes">

  # broadcasts_to ->(inbox) { :inbox_list }, target: 'inbox_collection'
  # requires a <%= turbo_stream_from :inbox_list %>
  # requires a <div id="inbox_collection">

  broadcasts_to ->(inbox) { :inbox_list }, inserts_by: :prepend, target: 'inboxes'
```

Sources:
* [turbo broadcastable source code](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb#L39)
* [turbo handbook](https://turbo.hotwired.dev/handbook/streams)




* no need to have turbo_stream_from in view (if we don't want to stream from the model *****)
* broadcast can not be triggered from console

****

* turbo_stream.update - you do not lose the frame.
* turbo_stream.replace - you lose the frame!
* it can seem to be an easy path to use after_commit broadcast in model, but more predictable in controllers.
* link_to_unless_current will return current from frame target
* the ones in the controller will not fire if created from console

****

refresh frame from and outside of frame
```html
<%= turbo_frame_tag @person do %>
  <%= @person.id %>
  <%= link_to @person.id, @person %>
  <%= Time.zone.now %>
<% end %>
<%# refresh frame from OUTSIDE of frame %>
<%= link_to @person.id, @person, data: { turbo_frame: dom_id(@person) } %>
<%= Time.zone.now %>
<hr>
```
