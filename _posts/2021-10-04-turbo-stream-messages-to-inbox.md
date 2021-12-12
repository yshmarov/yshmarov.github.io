---
layout: post
title: "#1 Turbo Stream messages to inbox. Render errors"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

### TASK 1: Create messages inside an inbox without refresh. Render form errors.

![hotwire-demo-1](/assets/images/hotwire-demo-1.gif)

### 0. Initial setup

My setup:
* Rails 7
* Ruby 3.0.1
* Hotwire (Stimulus + Turbo), pre-installed in Rails 7
* postgresql
* [=> My boilerplate app](https://github.com/yshmarov/turbo-playground)

Some options to create new Rails 7 app:
```sh
rails new superails -d=postgresql
rails new superails --main --d=postgresql --css=bulma
rails new superails -d=postgresql --skip-javascript
rails new superails -d=postgresql --css tailwind
rails new superails -d=postgresql --css bootstrap
rails new superails -d=postgresql --javascript esbuild --css bootstrap
```

Basic views and models:
```sh
rails g controller static_pages landing_page pricing privacy terms --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework
rails g scaffold Inbox name:string --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
rails g scaffold Message body:text inbox:references --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
rails db:migrate
```

#### 1. Turbo stream - stream [create, destroy, update] messages to inbox

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
Inbox.create(name: Faker::Lorem.sentence(word_count: 3))
Inbox.first.messages << Message.create(body: Faker::Lorem.sentence(word_count: 3))
Inbox.first.messages.first.update(body: SecureRandom.hex)
Inbox.first.messages.first.destroy
```

#### 2. Turbo stream - form to create messages. Error - form with errors. Success - new form.

* nested resources

#config/routes.rb
```ruby
  resources :inboxes do
    resources :messages, only: %i[create]
  end
```

* render form to create a new message inside an inbox

#app/views/inboxes/show.html.erb
```ruby
<%= render partial: "messages/form", locals: { message: Message.new } %>
```

* wrap the form into a turbo frame

#app/views/messages/_form.html.erb
```ruby
<%= turbo_frame_tag "message_form" do %>
  <%= form_with model: message, url: inbox_messages_path(@inbox) do |form| %>
  	...
  <% end %>
<% end %>
```

* send responce with `format.turbo_stream` to replace turbo frame with id `message_form` with partial `messages/form`

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

Resources:
* [Rails 7 alpha app boilerplate for exprimenting with hotwire](https://github.com/yshmarov/turbo-playground)
* [GITHUB: PR with changes from post #1](https://github.com/yshmarov/turbo-playground/pull/1)
* [Turbo Broadcastable options - GIT](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb)
* [Turbo Broadcastable options - Rubydoc](https://www.rubydoc.info/gems/turbo-rails/0.5.2/Turbo/Broadcastable)
* [post by @davidcolbyatx](https://dev.to/davidcolbyatx/using-hotwire-and-rails-to-build-a-live-commenting-system-aj9)
