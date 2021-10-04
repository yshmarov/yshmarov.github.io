---
layout: post
title: "Hotwire usecases. Part 1"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

Rails 7 app boilerplate for exprimenting with hotwire -> [HERE](https://github.com/yshmarov/askdemos)

[PR with changes from this post](https://github.com/yshmarov/askdemos/pull/1)

[This post](https://dev.to/davidcolbyatx/using-hotwire-and-rails-to-build-a-live-commenting-system-aj9) inspired me for #1 and #2

### TASK: Create messages inside an inbox without refresh. Render form errors.

![hotwire-demo](/assets/images/hotwire-demo-1.gif)

#### #1. Turbo streams - stream [create, destroy, update] messages to inbox

#app/models/message.rb
```ruby
  # lets you use dom_id in a model
  include ActionView::RecordIdentifier

  # add on top
  after_create_commit { broadcast_prepend_to [inbox, :messages], target: "#{dom_id(inbox)}_messages" }

  # add on bottom
  # after_create_commit { broadcast_append_to [inbox, :messages], target: "#{dom_id(inbox)}_messages" }

  after_destroy_commit { broadcast_remove_to [inbox, :messages], target: "#{dom_id(self)}" }

  after_update_commit { broadcast_update_to [inbox, :messages], target: "#{dom_id(self)}" }
```

[Turbo Broadcastable options](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb)

#app/views/inboxes/show.html.erb
```ruby
<%= turbo_stream_from @inbox, :messages %>
<div id="<%= "#{dom_id(@inbox)}_messages" %>">
  <%= render @inbox.messages %>
</div>
```

#app/views/messages/_message.html.erb
```ruby
<div id="<%= dom_id(message) %>">
  <%= message.body %>
</div>
```

Test in console
```sh
Inboxes.first.messages << Message.create(body: Faker::Lorem.sentence(word_count: 3))
Inboxes.first.messages.first.update(body: SecureRandom.hex)
Inboxes.first.messages.first.destroy
```

#### #2. Turbo streams - form to create messages. Error - form with errors. Success - new form.

#config/routes.rb
```ruby
  resources :inboxes do
    resources :messages, only: %i[create]
  end
```

#app/views/inboxes/show.html.erb
```ruby
<%= render partial: "messages/form", locals: { message: Message.new } %>
```

#app/views/messages/_form.html.erb
```ruby
<%= turbo_frame_tag "message_form" do %>
  <%= form_with model: message, url: inbox_messages_path(@inbox) do |form| %>
  	...
  <% end %>
<% end %>
```

#app/controllers/messages_controller.rb
```ruby
  def create
    @inbox = Inbox.find(params[:inbox_id])
    @message = @inbox.messages.new(message_params)

    respond_to do |format|
      if @message.save
        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          'message_form', 
          partial: 'messages/form', 
          locals: { message: Message.new }
        ) }
        # format.html { render partial: 'messages/form', locals: { message: Message.new }}
        format.html { redirect_to @message, notice: "Message was successfully created." }
        format.json { render :show, status: :created, location: @message }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          'message_form', 
          partial: 'messages/form', 
          locals: { message: @message }
        ) }
        # format.html { render partial: 'messages/form', locals: { message: @message }}
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end
```
