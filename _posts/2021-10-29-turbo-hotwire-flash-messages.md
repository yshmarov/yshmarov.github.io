---
layout: post
title: "#10 Turbo Streams - Create and stream records. Flash messages. Reusable Streams"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo turbo-streams flash
thumbnail: /assets/thumbnails/turbo.png
---

![turbo-flash](/assets/images/turbo-flash.gif)

### Problem:

When doing CRUD via turbo, without page redirect, you would STILL want to inform user with a flash message, right?

### 1. Basic Flash Setup:

* Default flash types: `notice`, `alert`
* `flash.now[:success]` - [available only in current action](https://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html#method-i-now){:target="blank"} (good for turbo)
* `flash[:success]` - available in next action (good for redirect)
* [ActionDispatch::Flash](https://api.rubyonrails.org/classes/ActionDispatch/Flash.html){:target="blank"}
* Use flash in `redirect_to`: `redirect_to inboxes_path, notice: "Inbox '#{inbox.id}' deleted."`
* Use a custom flash type: `redirect_to inboxes_path, flash: {new_type: "Inbox '#{inbox.id}' deleted."}`

****

* add a basic partial for flash messages

#app/views/shared/_flash.html.erb
```ruby
<div id="flash">
  <% flash.each do |key, value| %>
    <%= content_tag :div, value, id: key %>
  <% end %>
</div>
```

* render flash messages in layout

#app/views/layouts/application.html.erb 
```ruby
<%= render 'shared/flash' %>
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

### 2. Creating an inbox from index page with turbo:

#app/views/inboxes/index.html.erb
```diff
++ <div id="new_inbox">
++   <%= render partial: "inboxes/form", locals: { inbox: Inbox.new } %>
++ </div>

<div id="inboxes">
  <%= render @inboxes %>
</div>
```

#app/controllers/inboxes_controller.rb
```diff
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
++      format.turbo_stream do
++        render turbo_stream: [
++          turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }),
++          turbo_stream.prepend('inboxes', partial: 'inboxes/inbox', locals: { inbox: @inbox }),
++        ]
++      end
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
++      format.turbo_stream do
++        render turbo_stream: [
++          turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: @inbox }),
++        ]
++      end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @inbox.destroy
    respond_to do |format|
++    format.turbo_stream do
++      render turbo_stream: [
++        turbo_stream.remove(@inbox)
++      ]
      end
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

### 3. Finally, render flash with turbo:

#app/controllers/inboxes_controller.rb
```diff
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
++      flash.now[:notice] = "Inbox #{@inbox.id} created!"
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }),
            turbo_stream.prepend('inboxes', partial: 'inboxes/inbox', locals: { inbox: @inbox }),
++          turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
++      flash.now[:alert] = "Something went wrong"
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: @inbox }),
++          turbo_stream.update("flash", partial: "shared/flash")
          ]
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
++        turbo_stream.update("flash", partial: "shared/flash"),
          turbo_stream.remove(@inbox)
        ]
      end
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

### 4. flash as a reusable turbo stream in the controller:

#app/controllers/application_controller.rb
```diff
++  def render_turbo_flash
++    turbo_stream.update("flash", partial: "shared/flash")
++  end
```

#app/controllers/inboxes_controller.rb
```diff
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
++      flash.now[:notice] = "Inbox #{@inbox.id} created!"
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }),
            turbo_stream.prepend('inboxes', partial: 'inboxes/inbox', locals: { inbox: @inbox }),
++          render_turbo_flash,
--          turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
++      flash.now[:alert] = "Something went wrong"
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new_inbox', partial: 'inboxes/form', locals: { inbox: @inbox }),
++          render_turbo_flash,
--          turbo_stream.update("flash", partial: "shared/flash")
          ]
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
++        render_turbo_flash,
--        turbo_stream.update("flash", partial: "shared/flash"),
          turbo_stream.remove(@inbox)
        ]
      end
      format.html { redirect_to inboxes_url, notice: 'Inbox destroyed.' }
    end
  end
```

### 5. Auto-dismiss flash messages with Stimulus

app/javascript/controllers/autohide_controller.js
```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  dismiss() {
    this.element.remove()
  }
}
```

```diff
# app/views/shared/_flash.html.erb
<div id="flash">
++<div data-controller="autohide">
  <% flash.each do |key, value| %>
    <%= content_tag :div, value, id: "#{key}" %>
  <% end %>
++</div>
</div>
```

### 6. Stream and Display multiple flash messsages

* WRAP the parial into an ID

```diff
# app/views/layouts/application.html.erb
++<div id="flash" style="position:absolute; z-index:2; right:10px; width:200px;">
    <%= render 'shared/flash' %>
++</div>
```

* not in INSIDE the partial

```diff
# app/views/shared/_flash.html.erb
--<div id="flash">
  <div data-controller="autohide">
    <% flash.each do |key, value| %>
      <%= content_tag :div, value, id: "#{key}" %>
    <% end %>
  </div>
--</div>
```

* prepend new flash messages to have all of them visible on the page

```diff
-- turbo_stream.update("flash", partial: "shared/flash")
++ turbo_stream.prepend("flash", partial: "shared/flash")
```

That's it!