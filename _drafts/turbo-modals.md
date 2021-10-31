---
layout: post
title: "#20 Turbo: Modal."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo modals
thumbnail: /assets/thumbnails/turbo.png
---

/askdemos/app/views/inboxes/edit.html.erb
```diff
++<%= turbo_frame_tag "modal" do %>
  <%= render "form", inbox: @inbox %>
++<% end %>
```

Modal
Add a turbo frame tag to your layout

app/views/layouts/application.html.erb
```diff
<body>
++  <%= turbo_frame_tag "modal" %>
</body>
```

app/views/inboxes/_inbox.html.erb
```diff
--    <%= link_to "Edit", edit_inbox_path(inbox) %>
++    <%= link_to "Edit", edit_inbox_path(inbox), data: { turbo_frame: 'modal' } %>
```


```diff
-- <%= form_with(model: inbox) do |form| %>
++ <%= form_with(model: inbox, id: 'profile_form', data: { turbo_frame: "_top" }) do |form| %>
```

app/controllers/inboxes_controller.rb
```diff
  def create
    @inbox = Inbox.new(inbox_params)
    respond_to do |format|
      if @inbox.save
        format.html { redirect_to @inbox, notice: 'Inbox created.' }
      else
++        render(format.turbo_stream turbo_stream.update('profile_form', partial: 'inboxes/form', locals: {inbox: @inbox}))
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end
```
