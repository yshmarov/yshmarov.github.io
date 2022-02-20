---
layout: post
title: "Partial within a block"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails layouts rendering
thumbnail: /assets/thumbnails/turbo.png
---

https://stackoverflow.com/questions/2951105/rails-render-partial-with-block

https://guides.rubyonrails.org/layouts_and_rendering.html#understanding-yield

https://github.com/corsego/corsego/blob/main/app/views/courses/course_wizard/_step.html.haml

{:target="blank"}

### TLDR

* create a layout partial
```ruby
# /shared/_panel.html.erb
<%= title %>
<%= yield %>
<%= signature %>
```

```ruby
# Some View
<%= render layout: 'shared/panel',
           locals: { title: 'Dear team',
                     signature: 'Regards, Yaro' } do %>
  <p>Here is some content</p>
<% end %>
```

```ruby
Dear team
Here is some content
Regards, Yaro
```

****

### Real-world example

```ruby
# config/routes.rb
  resources :inboxes do
    member do
      get :message_list
      get :charts
    end
```

```ruby
# app/controllers/inboxes_controller.rb
  def show
    # inbox/:id/
    @inbox = Inbox.find(params[:id])
  end

  def message_list
    # inbox/:id/message_list
    # [:message_list, @inbox]
    @inbox = Inbox.find(params[:id])
  end

  def charts
    # inbox/:id/charts
    # [:charts, @inbox]
    @inbox = Inbox.find(params[:id])
  end
```

```ruby
# app/views/inboxes/_page.html.erb
<%= controller_name %>
<%= action_name %>
<%= request.path %>
<div id="player1" data-turbo-permanent>
  <input>
  <%= render inbox %>
</div>
<%= link_to_unless_current "Messages", [:message_list, inbox] %>
<%= link_to_unless_current "Chart", [:charts, inbox] %>
Header content
<%= yield %>
Footer content
```

```ruby
# app/views/inboxes/show.html.erb
<%= render layout: 'inboxes/page', locals: { inbox: @inbox } do %>
  <%= yield %>
<% end %>
```

```ruby
# app/views/inboxes/messages.html.erb
<%= render layout: 'inboxes/page', locals: { inbox: @inbox } do %>
  <%= yield %>
<% end %>

<%= render partial: 'inboxes/messages/message', collection: @inbox.messages %>
```

```ruby
# app/views/inboxes/charts.html.erb
<%= render layout: 'inboxes/page', locals: { inbox: @inbox } do %>
  <%= yield %>
<% end %>

<h1>Chart</h1>

<%= pie_chart @inbox.messages.group(:body).sum(:cached_votes_total) %>
```

****

```ruby
# layouts/_step.html.haml
header
<%= yield %>
footer
```

```ruby
<%= render layout: 'layouts/step' do %>
  Yo!
<% end %>
```