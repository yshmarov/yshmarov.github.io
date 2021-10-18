2021-10-07-hotwire-part-4-editing.md


### 1.

* go find frame with tag `inbox.id` in inboxes/id/edit

#app/views/inboxes/show.html.erb
```ruby
<%= turbo_frame_tag dom_id(@inbox) do %>
  <%= render @inbox %>
  <%= link_to "Edit", [:edit, @inbox] %>
<% end %>
```

#/askdemos/app/views/inboxes/_inbox.html.erb
```
no changes
```

* replace the `_inbox` partial and `Edit` with the content from the frame - `form` and `Cancel`

#app/views/inboxes/edit.html.erb
```ruby
<%= turbo_frame_tag dom_id(@inbox) do %>
  <%= render "form", inbox: @inbox %>
   <%= link_to "Cancel", @inbox %>
<% end %>
```

### ALTERNATIVE

#app/views/inboxes/show.html.erb
```
no changes
```

* invoke the inbox partial anywhere around the app

#app/views/inboxes/_inbox.html.erb
```
<%= turbo_frame_tag dom_id(inbox) do %>
<div id="<%= dom_id inbox %>" class="scaffold_record">
  <%= link_to "Edit", [:edit, inbox] %>
  <%= link_to_unless_current inbox.id, inbox %>
  <p>
    <strong>Name:</strong>
    <%= inbox.name %>
  </p>
</div>
<% end %>
```

#app/views/inboxes/edit.html.erb
<%= turbo_frame_tag dom_id(@inbox) do %>
  <%= render "form", inbox: @inbox %>
<% end %>
