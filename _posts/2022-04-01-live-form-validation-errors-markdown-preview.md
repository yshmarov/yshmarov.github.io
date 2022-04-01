---
layout: post
title: "Live form validation and error rendering. Live markdown previews"
author: Yaroslav Shmarov
tags: ruby rails html stimulusjs forms markdown
thumbnail: /assets/thumbnails/turbo.png
---

Here's how you can get `character count`, `error validation`, and `makdown preview` **while you type**, without page refresh, without extra JS

![live error validation and markdown previews](/assets/images/live-form-previews.gif)

### The trick:

1. let the form have a **second submit button** with a `different URL`
2. submit the `different URL`
3. the `different URL` will respond with a turbo_stream

### HOWTO:

```sh
rails generate scaffold Message content:text
rails g stimulus form
```

```ruby
# app/models/message.rb
  validates :content, presence: true
  validates :content, length: { in: 5..1000 }
```

* div id message_preview
* hidden button with formatction to a different url
* submit the hidden button oninput (with a stimulus controller)

```ruby
# app/views/messages/_form.html.erb
<%= form_with(model: message, data: { controller: "form", action: "input->form#remotesubmit" }) do |form| %>
  <div>
    <%= form.label :content, style: "display: block" %>
    <%= form.text_area :content %>
  </div>

  <div id="message_preview">
    <%= markdown message.content %>
  </div>

  <div>
    <%= form.button "Preview Message", formaction: preview_messages_path, name: "_method", value: "post", data: { form_target: "submitbtn" } %>
    <%= form.submit %>
  </div>
<% end %>
```

The Stimulus controller to:
* hide the second `submit` button
* autosubmit whenever there are any changes

```js
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitbtn"]

  // hide the submit button
  connect() {
    this.submitbtnTarget.hidden = true
  }

  // click the hidden button -> submit the form
  remotesubmit() {
    this.submitbtnTarget.click()
  }

  // same as above, but with "debounce"
  // remotesubmit() {
  //   clearTimeout(this.timeout)
  //   this.timeout = setTimeout(() => {
  //       this.submitbtnTarget.click()
  //     }, 500)
  // }
}
```

So now we try to send a request to the server each time we change something in the form...

We need a way to respond to it!

* create a new route that will respond to the second form `submit` button

```ruby
# config/routes.rb
  resources :messages do
    collection do
      post :preview
    end
  end
```

* create another message object from the submitted params
* respond with a turbo_stream

```ruby
# app/controllers/messages_controller.rb
  def preview
    # params.dig(:message, :content) 
    @preview = Message.new(message_params)

    respond_to do |format|
      format.turbo_stream
    end
  end
```

* update the `message_preview` with the attributes from the `@preview` object
* render errors, sanitized `@preview.content`, or anything based on the `@preview` object

```ruby
# app/views/messages/preview.turbo_stream.erb
<%= turbo_stream.update "message_preview" do %>
  <%= @preview.content.length %>
  <%= @preview.valid? %>
  <%= @preview.errors.full_messages %>
  <%= @preview.attributes %>
  <%= simple_format @preview.content %>
<% end %>
```

The drawback of this approach is having to exchange **MANY** request-responces with the server. Unlike a pure JS approach, that would handle everything on the client side.

****

This is inspired by the amazing idea of a form having a **second** submit button to a different URL, that was described in [Thoughtbot's: Server-rendered live previews](https://thoughtbot.com/blog/hotwire-server-rendered-live-previews)
