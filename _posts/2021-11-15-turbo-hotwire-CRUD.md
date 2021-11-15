---
layout: post
title: "#15 Turbo Streams CRUD"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo CRUD
thumbnail: /assets/thumbnails/turbo.png
---

![CRUD with turbo streams](/assets/images/turbo-streams-crud.gif)

There are 2 ways to use Turbo Streams:
1. Stream from controller action
* live page updates to **current_user**
* Example: you delete an item from a list - it is removed **for you** without page refresh
2. Broadcast callbacks from model
* live page updates to **all users on a page**
* Example: you delete an item from a list - it is removed **for all users on the page** without page refresh
* Perfect for LIVE CHAT.

**In most cases streaming from a controller action is enough.**

****

Plan:
* 0. Initial setup
* 1. CREATE an inbox. Turbo steam form.
* 2. ADD a created inbox to inboxes list with Controller Streams. Render multiple streams.
* 3. DESTROY an inbox with Controller Streams
* 4. EDIT an inbox with Controller Streams
* 5. NEXT LEVEL: Stream HTML. Update inboxes count on create/destroy.
* 6. Add basic flash functionality
* Bonus 1. Use `turbo_stream.erb` template!
* Bonus 2. *Deleted* message text
* Bonus 3. Update inboxes count on create/destroy. - Partial method

****

### 0. Initial setup

```sh
rails new askdemos -d=postgresql
rails g scaffold inbox name --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
```

```diff
# app/models/inbox.rb
++  validates :name, presence: true, allow_blank: false
```

### 1. CREATE an inbox. Turbo steam form.

* render form to create an inbox

```ruby
# app/views/inboxes/index.html.erb
<div id="new_inbox">
  <%= render partial: "inboxes/form", locals: { inbox: Inbox.new } %>
</div>
```

* re-render form for **new object** OR with **errors**
* use `update`, not `replace`

```diff
# app/controllers/inboxes_controller.rb
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

### 2. ADD a created inbox to inboxes list with Controller Streams. Render multiple streams.

* Notice how here we render 2 turbo_stream actions!

```diff
# app/controllers/inboxes_controller.rb
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
        format.turbo_stream do
--        render turbo_stream: turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new })
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
* [rendering multiple streams](https://github.com/hotwired/turbo-rails/issues/77){:target="blank"}

### 3. DESTROY an inbox with Controller Streams

* add "Destroy" link to the partial

```diff
# app/views/inboxes/_inbox.html.erb
<div id="<%= dom_id inbox %>" class="scaffold_record">
  <p>
    <strong>Name:</strong>
    <%= inbox.name %>
  </p>

  <p>
    <%= link_to "Show this inbox", inbox %>
++    <%= button_to "Destroy this inbox", inbox_path(inbox), method: :delete %>
  </p>
</div>
```

* the `remove` turbo_stream action is the only one that does not require a partial/html that will replace it.

```diff
# app/controllers/inboxes_controller.rb
  def destroy
    @inbox.destroy
    respond_to do |format|
++    format.turbo_stream { render turbo_stream: turbo_stream.remove(@inbox) }
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

### 4. EDIT an inbox with Controller Streams

**DISCLAIMER**: Consider this approach experimental. I don't really recommend this approach in production. You might want to use a `turbo_frame` instead of this!

* add "Edit" link to the partial
* it has to have `method: :post` - `turbo_stream` does not respond to `get`

```diff
# app/views/inboxes/_inbox.html.erb
<div id="<%= dom_id inbox %>" class="scaffold_record">
  <p>
    <strong>Name:</strong>
    <%= inbox.name %>
  </p>

  <p>
    <%= link_to "Show this inbox", inbox %>
--    <%= link_to "Edit this inbox", edit_inbox_path(inbox) %>
++    <%= button_to "Edit this inbox", edit_inbox_path(inbox), method: :post %>
    <%= button_to "Destroy this inbox", inbox_path(inbox), method: :delete %>
  </p>
</div>
```

* on click -> render a form to edit this inbox with a turbo stream
* in this case, the target `"inbox_#{@inbox.id}"` = `@inbox`

```diff
# app/controllers/inboxes_controller.rb
  def edit
++    respond_to do |format|
++      format.turbo_stream do
++        render turbo_stream: turbo_stream.update(@inbox, partial: 'inboxes/form', locals: { inbox: @inbox })
++      end
++    end
  end
```

* to make it work, `edit` should respond to `post`, not only to `get`
* YES, IT LOOKS HACKY!

```diff
# config/routes.rb
--  resources :inboxes
++  resources :inboxes do
++    member do
++      post :edit
++    end
++  end
```

`update` action:
* success - render `_inbox`
* failure - render `_form`

```diff
# app/controllers/inboxes_controller.rb
  def update
    respond_to do |format|
      if @inbox.update(inbox_params)
++        format.turbo_stream do
++          render turbo_stream: turbo_stream.update(@inbox, partial: 'inboxes/inbox', locals: { inbox: @inbox })
++        end
        format.html { redirect_to @inbox, notice: "Inbox was successfully updated." }
      else
++        format.turbo_stream do
++          render turbo_stream: turbo_stream.update(@inbox, partial: 'inboxes/form', locals: { inbox: @inbox })
++        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end
```

### 5. NEXT LEVEL: Stream HTML. Update inboxes count on create/destroy.

* add a target (a turbo_frame_tag that will be updated)

```diff
# app/views/inboxes/index.html.erb
++<span id="inbox_count">
++  <%= @inboxes.count %>
++</span>
```

* when created/destory event happens - replace above DOM with some TEXT/HTML

```diff
# app/controllers/inboxes_controller.rb
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
        format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }),
          turbo_stream.prepend('inboxes', partial: 'inboxes/inbox', locals: { inbox: @inbox })
++        # turbo_stream.update('inbox_count', html: "#{Inbox.count}")
++        turbo_stream.update('inbox_count', html: inboxes_count.html_safe)
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
--    format.turbo_stream { render turbo_stream: turbo_stream.remove(@inbox) }
++      format.turbo_stream do
++        render turbo_stream: [
++        turbo_stream.update('inbox_count', html: "#{Inbox.count}"),
++          turbo_stream.remove(@inbox)
++        ]
++      end
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

### 6. Add basic flash functionality

* create a notification partial

```ruby
# app/views/layouts/_messages.html.erb
<%= message %>
```

* target for displaying notifications

```diff
# app/views/layouts/application.html.erb
++<div id="notifications"></div>
<%= yield %>
```

```ruby
# app/controllers/inboxes_controller.rb

# add this to any action

# update - replace current message if present
turbo_stream.update(:notifications, partial: 'layouts/messages', locals: { message: "#{Time.zone.now}" })

# prepend - add to list
# turbo_stream.prepend(:feed, partial: 'layouts/messages', locals: { message: "#{Time.zone.now}" })
```

### Bonus 1. Use `turbo_stream.erb` template!

Writing bulky turbo_streams in the conroller can feel wrong.

Instead, the correct way to respond to `format.turbo_stream` is to render a template.

Example:

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
### Bonus 2. *Deleted* message text

* When deleting an inbox, consider replacing it with an html "deleted" message:

```diff
# app/controllers/inboxes_controller.rb
  def destroy
    @inbox.destroy
    respond_to do |format|
++      format.turbo_stream { render turbo_stream: turbo_stream.update(@inbox, html: "Inbox #{@inbox.id} deleted") }
      format.html { redirect_to inboxes_url, notice: "Inbox was successfully destroyed." }
    end
  end
```

### Bonus 3. Update inboxes count on create/destroy. - Partial method

* create a partial with a local variable

```ruby
#app/views/inboxes/_count.html.erb
<%= inboxes_count %>
```

* add a target
* optionally, render the partial with some local variable by default

```ruby
#app/views/inboxes/index.html.erb
<div id="inbox_count">
  <%= render partial: 'inboxes/count', locals: { inboxes_count: Inbox.count } %>
</div>
```

* in controller

```diff
#app/controllers/inboxes_controller.rb
def create
	...
  respond_to do |format|
    if @inbox.save
      format.turbo_stream do
        render turbo_stream: [
++          turbo_stream.update('inbox_count', partial: 'inboxes/count', locals: { inboxes_count: Inbox.count })
        ]
			end

def destroy
	...
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
++        turbo_stream.update('inbox_count', partial: 'inboxes/count', locals: { inboxes_count: Inbox.count })
      ]
    end
```

### That's it!
