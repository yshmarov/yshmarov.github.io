https://www.colby.so/posts/conditional-rendering-with-turbo-stream-broadcasts
https://www.colby.so/posts/turbo-streams-on-rails

app/views/inboxes/index.html.erb
```ruby
<%= turbo_frame_tag 'feed', target: "_top" do %>
<div id="inboxes">
  <%= render @inboxes %>
</div>
<% end %>
```

Now, link to `show inbox` will not target this turbo frame tag

[LEARN MORE](https://turbo.hotwired.dev/handbook/frames#targeting-navigation-into-or-out-of-a-frame)

#### 3.1. Click `Pricing` - replace content in this turbo frame tag with result from pricing.html.erb

Destination page:

#app/views/static_pages/pricing.html.erb
```ruby
<h1>Pricing<h2>
<%= turbo_frame_tag 'feed' do %>
  This is the result from pricing
<% end %>
```

Source page:

#app/views/static_pages/landing_page.html.erb
```ruby
<h1>Landing page<h2>
<%= turbo_frame_tag 'feed' do %>
  <%= link_to 'Pricing', pricing_path %>
<% end %>
```

#### 3.2. Lazy load result from pricing.html.erb
```ruby
<%= turbo_frame_tag 'feed', src: pricing_path %>
```

#### 3.3. Lazy load with placeholder
```ruby
<%= turbo_frame_tag 'feed', src: pricing_path, loading: :lazy do %>
  Loading...
<% end %>
```
#### 3.4. Lazy load with placeholder - HTML
```ruby
<turbo-frame id="feed" src="/pricing">
  Loading...
</turbo-frame>
```
#### 3.5. Load partial or collection inside a turbo frame

#app/views/static_pages/pricing.html.erb
```ruby
<%= turbo_frame_tag 'feed' do %>
  <%= render partial: 'inboxes/form', locals: { inbox: Inbox.new } %>
  <%= render partial: "inboxes/inbox", collection: Inbox.all %>
<% end %>
```

#### target top ?????????
<%= turbo_frame_tag 'inboxes', src: inboxes_path, target: "_top" %>


### 4. Turbo frame - edit inbox

#app/views/inboxes/_inbox.html.erb
```ruby
  <%= turbo_frame_tag dom_id(inbox) do %>
    <p>
      <strong>Name:</strong>
      <%= inbox.name %>
    </p>
    <%= link_to 'Edit', [:edit, inbox] %>
  <% end %>
```

#app/views/inboxes/edit.html.erb
```ruby
<%= turbo_frame_tag dom_id(@inbox) do %>
  <%= render "form", inbox: @inbox %>
<% end %>
```

### 3. turbo frame - form to create messages in an inbox show

```ruby
<%= render partial: "inboxes/form", locals: {inbox: Inbox.new} %>
```

### 1. turbo stream - new inboxes to inboxes/index
### 2. turbo frame - create new inboxes, render form with validations
### 3. turbo stream - append / prepend / destory
### 4. turbo stream - broadcast all activity
### 3. turbo frame - edit
### button to show inside turbo frame?
### button to destroy CORS inside turbo frame?
### turbo stream - messages to inbox
### turbo frame - messages to inbox
### turbo frame - edit message in an inbox
### turbo stream - destroy message in an inbox


#app/views/comments/_comment.html.erb
```ruby
<%= turbo_frame_tag dom_id(comment) do %>
  <blockquote>
    <%= comment.body %>

    <footer>
      <%= link_to 'Edit', [:edit, comment.post, comment] %> | <%= l comment.updated_at, format: :long %>
    </footer>
  </blockquote>
<% end %>
```
#app/views/comments/edit.html.erb
```ruby
<h1>Editing Comment</h1>

<%= turbo_frame_tag dom_id(@comment) do %>
  <%= render 'form', comment: @comment %>
<% end %>

<%= link_to 'Show', url_for([@comment.post, @comment]) %> |
<%= link_to 'Back', url_for([@comment.post]) %>
```




### Good
#app/views/inboxes/index.html.erb
```ruby
  <%= render partial: "inboxes/form", locals: { inbox: Inbox.new } %>
```
#app/views/inboxes/_form.html.erb
```ruby
<%= turbo_frame_tag 'inbox_form' do %>
  ...
<% end %>
```
### Better
#app/views/inboxes/index.html.erb
```ruby
<%= turbo_frame_tag 'inbox_form' do %>
  <%= render partial: "inboxes/form", locals: { inbox: Inbox.new } %>
<% end %>
```
### The best
#app/views/inboxes/index.html.erb
```ruby
<%= turbo_frame_tag 'new_inbox', src: new_inbox_path, target: "_top" %>
```
#app/views/inboxes/new.html.erb
```ruby
<%= turbo_frame_tag 'new_inbox' do %>
  <%= render "form", inbox: @inbox %>
<% end %>
```


<%= form_with(model: inbox, data: { controller: 'reset-form', action: 'turbo:submit-end->reset_form#reset'}) do |form| %>


app/javascript/controllers/reset_form_controller.js
app/views/inboxes/create.turbo_stream.erb
<%= turbo_stream.append 'messages', @message %>


<%= turbo_stream.replace('new_inbox', partial: 'inboxes/form', locals: { inbox: Inbox.new }) %>

#### Turbo Frame

/askdemos/app/views/static_pages/landing_page.html.erb
<%= turbo_frame_tag 'inboxes', src: inboxes_path, loading: :lazy, target: "_top" do %>
  Loading...
<% end %>

/askdemos/app/views/inboxes/index.html.erb
<%= turbo_frame_tag 'inboxes' do %>
  <div id="inboxes">
    <%= render @inboxes %>
  </div>
<% end %>

#### STIMULUS

```sh
stimulus:manifest:update
```

Add an nmp package with importmap
```sh
bin/importmap pin sortablejs
bin/importmap pin sortablejs --from jsdelivr
```

# app/javascript/controllers/position_controller.js
```javascript
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
export default class extends Controller {

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150
    })
  }
}
```
# views/welcome/index.html.erb
```
<ul data-controller="position">
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
  <li>Item 4</li>
</ul>
```

****

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

****

```ruby
# seeds.rb
print('.')
puts '.All Ok!'
```
https://api.rubyonrails.org/classes/ActiveModel/Errors.html
