---
layout: post
title: "Dynamic forms with Turbo"
author: Yaroslav Shmarov
tags: ruby-on-rails hotwire turbo chained-select
thumbnail: /assets/thumbnails/numbered-list.png
---

In the previous post we explored **Cascading Select Fields**.

When selecting a `country`, we had to submit a form and return an `error` in order to see the related `cities`.

???
If the problem is just about showing/hiding a field, I would do it with stimulus
_posts/2021-06-03-stimulus-display-show-hide-div-based-on-value.md
[Gif show/hide password]
???

We were close to solving such a problem in a previous post:
[Live form validations and error rendering. Live markdown preview]({% post_url 2022-04-01-live-form-validation-errors-markdown-preview %})
, where we:
* added an additional `POST` button to the form with a separate url
* the button answered to a separate controller action
* the button was submitted whenever anything changed in the form
* the controller action answered with a `turbo_stream`

Something similar can be achieved with (possibly) less friction using `turbo_frames`.

Instead of having a `POST` button we will have a `GET` button that will target a `turbo_frame`. Content inside the `turbo_frame` will be refreshed based on the submitted params.

### 1. Initial setup

```sh
rails g scaffold document access passcode content:text
```

```ruby
# app/models/document.rb
class Document < ApplicationRecord
  enum access: {
    publish: 'publish',
    draft: 'draft',
    passcode_protected: 'passcode_protected'
  }

  with_options presence: true do
    validates :access
    validates :passcode, if: :passcode_protected?
    validates :content
  end
end
```

```ruby
# app/views/documents/_form.html.erb
<%= form.select :access, Document.accesses.keys, { include_blank: true }, {} %>
<% if @document.access.present? %>
  <%= form.text_field :passcode %>
<% end %>
```

validation-based errors are important for the future steps.

[GIF submit-errors]

### 2. button to validate

full page refresh with selected passcode params

```diff
# app/views/documents/_form.html.erb
<%= form.select :access, Document.accesses.keys, { include_blank: true }, {} %>
++<%= form.button "Validate", formaction: new_document_path, name: "_method", value: "get" %>
<% if @document.access.present? %>
  <%= form.text_field :passcode %>
<% end %>
```

```diff
# app/controllers/documents_controller.rb
  def new
    # re-create object with passed params
-    @document = Document.new
+    @document = Document.new document_params
  end

  def document_params
    # allow empty params
-    params.permit(:document).permit(:content, :access, :passcode)
+    params.fetch(:document, {}).permit(:content, :access, :passcode)
  end
```

[GIF submit-refreshed form with params]

### 3. Stimulus: autosubmit `Validate` button

No need to actually click a button

```sh
rails g stimulus form
```

```js
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

// action="change->form#remotesubmit"
// action="input->form#remotesubmit"
// Connects to data-controller="form"
export default class extends Controller {
  static targets = ["submitbtn"]

  connect() {
    this.submitbtnTarget.hidden = true
  }

  remotesubmit() {
    // this.submitbtnTargets.forEach(target => target.click())
    this.submitbtnTarget.click();
  }
}
```

```diff
# app/views/documents/_form.html.erb
+<div data-controller="form">
<%= form.select :access, Document.accesses.keys, { include_blank: true }, { data: { action: "change->form#remotesubmit" } } %>
-<%= form.button "Validate", formaction: new_document_path, name: "_method", value: "get" %>
+<%= form.button "Validate", formaction: new_document_path, name: "_method", value: "get", data: { form_target: "submitbtn" } %>
<% if @document.access.present? %>
  <%= form.text_field :passcode %>
<% end %>
+</div>
```

[GIF auto-submit]

### 4. refresh Frame, not full page

if text field (input vs change); 
stay on the same place in the page

```diff
<div data-controller="form">
<%= form.select :access, Document.accesses.keys, { include_blank: true }, { data: { action: "change->form#remotesubmit" } } %>
-<%= form.button "Validate", formaction: new_document_path, name: "_method", value: "get", data: { form_target: "submitbtn" } %>
+<%= form.button "Validate", formaction: new_document_path, name: "_method", value: "get", data: { form_target: "submitbtn", turbo_frame: :passcode_field } %>
+<%= turbo_frame_tag :passcode_field %>
<% if @document.access.present? %>
  <%= form.text_field :passcode %>
<% end %>
+<% end %>
</div>
```

### 5. Next level: include a Turbo Stream inside a Turbo Frame

can update content anywhere on the page (with a conditional turbo_stream inside the frame), not only inside the frame

```diff
<div data-controller="form">
<%= form.select :access, Document.accesses.keys, { include_blank: true }, { data: { action: "change->form#remotesubmit" } } %>
<%= form.button "Validate", formaction: new_document_path, name: "_method", value: "get", data: { form_target: "submitbtn", turbo_frame: :passcode_field } %>
<%= turbo_frame_tag :passcode_field %>
<% if @document.access.present? %>
  <%= form.text_field :passcode %>
+  <%= turbo_stream.update "abc", html: "bingo winner!" %>
+  <%= turbo_stream.update :passcode_field, partial: "documents/passcode_fields", locals: {form: form} %>
<% end %>
<% end %>
</div>
```

### 6. BUGFIX: reset form on page refresh

when you refresh a page some form fields can stay filled in because of the browser cache. can look weird when dynamic fields required. reset the form!

```js
// app/controllers/reset_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.reset()
  }
}
```

```diff
# app/views/documents/_form.html.erb
-<%= form_with(model: document) do |form| %>
+<%= form_with(model: document, data: { controller: "reset-form" }) do |form| %>
```

### Other thoughts

#### add fields with HTML? or form.field ?

```ruby
<%= form.button "Validate",
                formaction: new_document_path,
                name: "_method",
                value: "get",
                data: { form_target: "submitbtn",
                        turbo_frame: form.field_id(:passcode, :turbo_frame) } %>
```

```html
<noscript>
  <button formmethod="get" formaction="<%= new_document_path %>">Validate</button>
</noscript>

<button formmethod="get" 
        formaction="<%= new_document_path %>"
        hidden
        data-element-target="submitbtn"
        data-turbo-frame="<%= form.field_id(:content, :turbo_frame) %>">Validate</button>
```

Inspired by [thoughtbot: dynamic forms with turbo](https://thoughtbot.com/blog/dynamic-forms-with-turbo)

#### button vs submit

Below, `form.button` = `form.submit`:

```ruby
<%= form.submit "form submit",  formaction: new_post_path, formmethod: :get, data: { form_target: "submitbtn", turbo_frame: :dynamic_fields } %>
```
generates html:
```html
<input type="submit" name="commit" value="form subm" formaction="/posts/new" formmethod="get" data-form-target="submitbtn" data-turbo-frame="dynamic_fields" data-disable-with="form subm">
```
VS
```ruby
<%= form.button "form button", formaction: new_post_path, name: "_method", value: "get", data: { form_target: "submitbtn", turbo_frame: :dynamic_fields } %>
```
generates html:
```html
<button name="_method" type="submit" formaction="/posts/new" value="get" data-form-target="submitbtn" data-turbo-frame="dynamic_fields">form butn</button>
```
