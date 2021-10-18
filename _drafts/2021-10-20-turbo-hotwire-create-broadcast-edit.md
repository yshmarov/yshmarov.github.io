---
layout: post
title: "#8 Turbo Frames and Streams - Create Inboxes, render erros, edit, stream CRUD."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails request-params hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

#app/views/inboxes/index.html.erb
```ruby
<%= render partial: "inboxes/form", locals: { inbox: Inbox.new } %>
<%= turbo_stream_from :inboxes_magic %>
```

#app/controllers/inboxes_controller.rb#create
```ruby
def create
	...
	if @inbox.save
	  format.turbo_stream do
	    render turbo_stream: turbo_stream.prepend('inboxes', partial: 'inboxes/inbox', locals: { inbox: @inbox })
	  end
	end
	...
end
```

#app/models/inbox.rb
```ruby
  broadcasts_to ->(inbox) { 'inboxes_magic' },
    inserts_by: :prepend,
    target: 'inboxes'
```

### 2. Editing an inbox

* wrap it into a turbo_frame with the id of the inbox
* you don't have to use dom_id. turbo_frame_tag will convert the inbox object into a dom_id automatically
* to make link_to SHOW work, break out of the frame
* to make link_to EDIT work, you can stay in the frame
* * YARO - maybe target top by default?!

#app/views/_inbox.html.erb
```ruby
<%= turbo_frame_tag inbox, class: "scaffold_record" do %>
  <%= link_to_unless_current inbox.name, inbox, data: { turbo_frame: '_top' } %>
  <%= link_to "Edit", edit_inbox_path(inbox) %>
  <%= button_to "Destroy", inbox_path(inbox), method: :delete %>
<% end %>
```

* when you click "Edit", 

```ruby
#app/views/inboxes/edit.html.erb
<%= turbo_frame_tag @inbox, class: "scaffold_record" do %>
  <%= render "form", inbox: @inbox %>
<% end %>
```

* when you submit, it will re-render the _inbox partial from the show page
