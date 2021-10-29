---
layout: post
title: "#9 Turbo Streams - a complete practical guide."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo turbo-streams
thumbnail: /assets/thumbnails/turbo.png
---

Plan
1. Edit an inbox
2. Create an inbox
3. VIA MODEL: Stream a created inbox to inboxes list
4. VIA CONTROLLER: Stream a created inbox to inboxes list
5. VIA CONTROLLER: Destroy an inbox
6. VIA CONTROLLER: Stream HTML. Update inboxes count on create/destroy.

5. Counter for create/destroy
6. Multiple streams from controller
7. Multiple streams from action_name.turbo_stream.erb

sorting, filtering
button to replace big frame
button to replace small frame
navigate between frames / 
break in//out of frames
SPA

### +1. Edit an inbox

* wrap inbox partial into a turbo_frame with the id of the inbox
* remove the div with the dom id
* you don't have to use dom_id. turbo_frame_tag will convert the inbox object into a dom_id automatically
* to make link_to SHOW work, break out of the frame
* to make link_to EDIT work, you can stay in the frame
* FUTURE CONSIDERATION: maybe target top by default on this frame?

```ruby
#app/views/_inbox.html.erb
<%= turbo_frame_tag inbox, class: "scaffold_record" do %>
  <%= link_to inbox.name, inbox, data: { turbo_frame: '_top' } %>
  <%= link_to "Edit", edit_inbox_path(inbox) %>
  <%= button_to "Destroy", inbox_path(inbox), method: :delete %>
<% end %>
```

* when you click "Edit", the frame will be replaced with content from frame with same ID on "Edit" page
* when you submit, it will redirect to "Show" page and re-render the inbox partial that it finds there

```diff
#app/views/inboxes/edit.html.erb
++ <%= turbo_frame_tag @inbox do %>
<%= render "form", inbox: @inbox %>
++ <% end %>
```

### +2. Create an inbox

* 1.1. render partial in a turbo_frame

```ruby
#app/views/inboxes/index.html.erb
<div id="new_inbox">
  <%= render partial: "inboxes/form", locals: { inbox: Inbox.new } %>
</div>
```

* 1.2. controller re-render form (update, not replace)

```diff
#app/controllers/inboxes_controller.rb
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
++        format.turbo_stream do
++          render turbo_stream: turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new })
++        end
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
++        format.turbo_stream do
++          render turbo_stream: turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: @inbox})
++        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end
```

### +3. VIA MODEL: Stream a created inbox to inboxes list

* fix CSFR errors when streaming `button_to`

```diff
#config/application.rb
++		config.action_controller.silence_disabled_session_errors = true
```

* many ways to set up broadcasting from the model
* DELETE DOES NOT FIRE A CALLBACK. DESTROY DOES.

Turbo stream actions:
* `append`
* `prepend`
* `replace`
* `update`
* `remove`
* `before`
* `after`
Callbacks:
* `after_update_commit`
* `after_create_commit`
* `after_destroy_commit`
* `after_save_commit`

In a turbo_stream you can specify (to be confirmed):
* a `turbo_stream_from` broadcast to listen to 
* a `turbo_frame_for` target (or `div id`)
* a partial to stream (or just some HTML)
* locals of the partial

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

* add a target anywhere on the index page
* by default it will target dom with id "inboxes", but you can also overwrite it

```diff
#app/views/inboxes/index.html.erb
++ <%= turbo_stream_from :inbox_list %>
```

### +4. VIA CONTROLLER: Stream a created inbox to inboxes list. Render multiple streams

* Notice how here we render 2 turbo_stream actions!
* no need to have turbo_stream_from in view (if we don't want to stream from the model *****)
* broadcast can not be triggered from console

```diff
#app/controllers/inboxes_controller.rb
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
        format.turbo_stream do
++        render turbo_stream: [
++          turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }),
++          turbo_stream.prepend('inboxes', partial: 'inboxes/inbox', locals: { inbox: @inbox })
++        ]
        end
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: @inbox })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end
```

Source:
* [rendering multiple streams](https://github.com/hotwired/turbo-rails/issues/77)

### +5. VIA CONTROLLER: Destroy an inbox

If you do not stream `destroy` from your model, you should have it in the controller.

If in our case you do not stream destroy:

When you click destroy, the inbox will disappear and the page will not refresh. 

Why?

Because the inbox partial is in a turbo_frame_tag. You click destroy, it tries to go to the "destroy" url and find a matching frame.

This is not the perfect behavior.

```diff
#app/controllers/inboxes_controller.rb
  def destroy
    @inbox.destroy
    respond_to do |format|
++    format.turbo_stream { render turbo_stream: turbo_stream.remove(@inbox) }
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

### +6. VIA CONTROLLER: Stream HTML. Update inboxes count on create/destroy.

* add a target (a turbo_frame_tag that will be updated)

```diff
++ <%= turbo_frame_tag 'inbox_count' do %>
++   <%= @inboxes.count %>
++ <% end %>
```

* when created/destory event happens - replace above frame with some HTML

```diff
#app/controllers/inboxes_controller.rb
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }),
            turbo_stream.prepend('inbox_collection', partial: 'inboxes/inbox', locals: { inbox: @inbox }),
++          # turbo_stream.update('inbox_count', html: "#{Inbox.count}")
++          turbo_stream.update('inbox_count', html: inboxes_count.html_safe)
          ]
        end
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: @inbox })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

++  def inboxes_count
++    "<b>#{Inbox.count}</b>"
++  end

  def destroy
    @inbox.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
++        turbo_stream.update('inbox_count', html: "#{Inbox.count}"),
          turbo_stream.remove(@inbox)
        ]
      end
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

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

### +8. Flash messages with Turbo. Reusable Streams. Dismiss flash.

Theory:

Default types: `notice`, `alert`

* `flash.now[:success]` - available only in current action (good for turbo)
* `flash[:success]` - available in next action (good for redirect)
* [ActionDispatch::Flash](https://api.rubyonrails.org/classes/ActionDispatch/Flash.html)
* Use flash in `redirect_to`: `redirect_to inboxes_path, notice: "Inbox '#{inbox.id}' deleted."`
* Use a custom flash type: `redirect_to inboxes_path, flash: {new_type: "Inbox '#{inbox.id}' deleted."}`

Practice:

* add a basic partial for flash messages
* link_to x - tricky way to dismiss the parial with turbo frames

```ruby
#app/views/shared/_flash.html.erb
<% flash.each do |key, value| %>
  <%= content_tag :div, value, id: "#{key}" %>
<% end %>
<%= link_to 'x', "#" if flash.any?%>
```

* render flash messages in layout
* wrap into a turbo_frame_tag

```ruby
#app/views/layouts/application.html.erb 
<%= turbo_frame_tag :flash do %>
  <%= render 'shared/flash' %>
<% end %>
```

* some css styling for the available flash message types:

#app/assets/stylesheets/application.css
```css
#notice {
  border-radius: 6px;
  padding: 6px;
  color: white;
  background: green;
}

#alert {
  border-radius: 6px;
  padding: 6px;
  color: white;
  background: red;
}
```

* flash will be a reusable turbo stream:

```diff
#app/controllers/application_controller.rb
++  def render_turbo_flash
++    turbo_stream.update("flash", partial: "shared/flash")
++    # render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
++  end
```

* render flash with a turbo stream from the controller:

```diff
#app/controllers/inboxes_controller.rb
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
        format.turbo_stream do
++        # available only on current page (good for turbo responce)
++        flash.now[:notice] = "Inbox #{@inbox.id} created!"
++        # available also on redirect page (good for non-turbo responce)
++        # flash[:notice] = "Inbox #{@inbox.id} created!"
          render turbo_stream: [
            turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }),
            turbo_stream.prepend('inbox_collection', partial: 'inboxes/inbox', locals: { inbox: @inbox }),
            # turbo_stream.update('inbox_count', html: "#{Inbox.count}")
++          render_turbo_flash,
            turbo_stream.update('inbox_count', html: inboxes_count.html_safe)
          ]
        end
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: @inbox })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @inbox.destroy
++  flash.now[:alert] = "Inbox #{@inbox.id} destroyed!"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
++				render_turbo_flash,
          turbo_stream.update('inbox_count', html: "#{Inbox.count}"),
          turbo_stream.remove(@inbox)
        ]
      end
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

### +9. Display flow of partial(s) when an event happens

* create a notification partial

```ruby
#app/views/shared/_notification.html.erb
<%= message %>
```

* target for displaying notifications

```diff
#app/views/layouts/application.html.erb
	<body>
++  <%= turbo_frame_tag :feed %>
		<%= yield %>
```

* send notification partial with a turbos stream
* pass a locale to set the message text
* USING PREPEND HERE! :D

```ruby
turbo_stream.prepend(:feed, partial: 'shared/notification', locals: { message: "#{Time.zone.now}" })
```

### +10. Increase/Decrease Counter if record is created/destroyed - Partial method

```ruby
#app/views/inboxes/_count.html.erb
<%= inboxes_count %>
```

```ruby
#app/views/inboxes/index.html.erb
<%= turbo_frame_tag 'inbox_count' do %>
  <%= render partial: 'inboxes/count', locals: { inboxes_count: Inbox.count } %>
<% end %>
```

* in controller

```ruby
#app/controllers/inboxes_controller.rb
def create
	...
  respond_to do |format|
    if @inbox.save
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('inbox_count', partial: 'inboxes/count', locals: { inboxes_count: Inbox.count })
        ]
			end

def destroy
	...
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.update('inbox_count', partial: 'inboxes/count', locals: { inboxes_count: Inbox.count })
      ]
    end
```

### Conditionally resond with turbo or html?
### FLASH for update?
### Stream HTML via model?

### 9. `create.turbo_stream.erb`

[e](https://github.com/hotwired/turbo-rails/blob/ba86832f7f13001793ab917185788df9723666e8/app/helpers/turbo/streams_helper.rb)

* alternatively - respond to `format.turbo_stream` with a separate file

```ruby
#app/controllers/inboxes_controller.rb
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
        format.turbo_stream
```

```ruby
#app/views/inboxes/create.turbo_stream.erb
<%= turbo_stream.update "inbox_count" do %>
  <%= render partial: 'count', locals: { inboxes_count: Inbox.count } %>
<% end %>
```

****

* good example place to both prepend the created inbox AND put up a new form (without resorting to the model)
* turbo_stream.update - you do not lose the frame.
* turbo_stream.replace - you lose the frame!
* it can seem to be an easy path to use after_commit broadcast in model, but more predictable in controllers.
* link_to_unless_current will return current from frame target
* the ones in the controller will not fire if created from console

****

## teams/show.html.erb
#<%= turbo_stream_from @team %>
#
## player.rb
#belongs_to :team
#
#after_create_commit { broadcast_append_later_to(team) }
#after_destroy_commit { broadcast_remove_to(team) }

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