---
layout: post
title: "#16 Turbo Streams: Edit Modal."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo modals
thumbnail: /assets/thumbnails/turbo.png
---

Objective:
* press "Edit"
* open a **modal** to "Edit" this specific record
* edit the record. display errors if needed
* on success - dismiss modal, update record
* be able to **dismiss** the modal without submit

![turbo stream edit modal](/assets/images/TURBO-STREAM-MODALS.gif)

### 0. Initial setup

```sh
rails g scaffold post title
rails db:migrate
```

```diff
# app/models/post.rb
class Post < ApplicationRecord
++  validates :title, presence: true
end
```

### 1.1. Add a modal

* Add a target in the layout, so that you can make modals available in the whole app:

```diff
# app/views/layouts/application.html.erb
++    <div id="modal"></div>
      <%= yield %>
```

* The key to making a modal look like a modal is the CSS:

```css
/* app/assets/application.css */
#modal {
  position: absolute;
  z-index: 2;
  right: 10px;
  width: 200px;
  word-break: break-word;
  border-radius: 6px;
  background: #bad5ff;
}
```

### 1.2. Open modal with `Edit` form with Turbo Streams:

* Make `Edit` button `respond_to` method `POST`, so that it can respond to a `turbo_stream`:

```diff
# config/routes.rb
--  resources :posts
++  resources :posts do
++    member do
++      post :edit
++    end
++  end
```

* Add the `Edit` `button_to` with `method: :post` to the partial:

```diff
# app/views/posts/_post.html.erb
++    <%= button_to "Edit", edit_post_path(post), method: :post %>
```

* click edit -> open the modal

```diff
  def edit
++    respond_to do |format|
++      format.turbo_stream do 
++        # render turbo_stream: turbo_stream.update('modal', partial: "posts/form", locals: {post: @post})
++        render turbo_stream: turbo_stream.update('modal', template: "posts/edit", locals: {post: @post})
++      end
++    end
  end
```

* Notice, in the above approach I offer 2 options of rendering a `partial` or a `template`. 
* Try both, see which one fits your case better!

### 1.3. Modal behavior: Update/Errors/Close

* update success -> close modal, update element on the page
* update error -> re-render modal with errors

```diff
# app/controllers/posts_controller.rb
  def update
    respond_to do |format|
      if @post.update(post_params)
++        format.turbo_stream do 
++          render turbo_stream: [
++            turbo_stream.update(@post, partial: 'posts/post', locals: {post: @post}),
++            turbo_stream.update('modal', nil)
++          ]
        end
        format.html { redirect_to @post, notice: "Post was successfully updated." }
      else
++        format.turbo_stream do 
++          # render turbo_stream: turbo_stream.update('modal', partial: "posts/form", locals: {post: @post})
++          render turbo_stream: turbo_stream.update('modal', template: "posts/edit", locals: {post: @post})
++        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end
```

### 2. Dismiss modal without save

* A stimulus controller will do the job perfectly!

```js
// app/controllers/click2hide_controller.js
import { Controller } from "@hotwired/stimulus"

// <div data-controller="click2hide">
// <button data-action="click->click2hide#dismiss">
//   Close
// </button>

export default class extends Controller {
  connect() {
    console.log("click2hide controller connected")
  }

  dismiss () {
    this.element.remove();
  }
}
```

* Wrap the partial/template that is rendered into the controller.
* Add a button to Cancel/Close

```diff
# app/views/posts/_post.html.erb
++<div data-controller="click2hide">
<%= form_with(model: post) do |form| %>
    <%= form.text_field :title %>
    <%= form.submit %>
<% end %>
++<button data-action="click->click2hide#dismiss">
++  Cancel
++</button>
++</div>
```

That's it!
