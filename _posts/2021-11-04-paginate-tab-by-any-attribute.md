---
layout: post
title: "Paginate/Tab records by any attribute"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails pagination tabs
thumbnail: /assets/thumbnails/pagination.png
---

Just think about it: `pagination` = `tabs`.

From this point of view, It's easy to add pagination/tabs by any attribute.

For example, pagination/tabs by date:

![paginate-by-date](/assets/images/paginate-by-date.gif)

### 1. Paginate/Tab by Date

```sh
rails g scaffold post name category published_at:datetime
rails db:migrate
```

```ruby
# config/seeds.rb
5.times do
  random_date = Time.at(rand * Time.now.to_i)
  random_category = %w[ruby python java].sample
  post = Post.create(name: SecureRandom.hex,
                     category: random_category,
                     published_at random_date)
end
```

```ruby
# app/controllers/posts_controller.rb
  def index
    @posts = if params[:category].present?
                 Post.where(category: params[:category])
               else
                 Post.all
               end
  end
```

```ruby
# app/views/posts/index.html.erb
Publication date:
<% Inbox.pluck(:published_at).uniq.sort.each do |i| %>
  <br>
  <%= link_to_unless_current i.strftime('%d/%m/%y'), inboxes_path(date: i) %>
<% end %>
<br>
<div id="inboxes">
  <%= render @inboxes %>
</div>
```

### Paginate/Tab by Category

```ruby
# app/controllers/posts_controller.rb
  def index
    @posts = if params[:date].present?
                 Post.where(published_at: params[:date])
               else
                 Post.where(published_at: Date.today)
               end
  end
```

```ruby
# app/views/posts/index.html.erb
Categories:
<% Post.all.pluck(:category).uniq.sort.each do |category| %>
  <%= link_to_unless_current category, posts_path(category: category) %>
<% end %>
<%= link_to "Clear filters", request.path if request.query_parameters.any? %>
<br>
<div id="inboxes">
  <%= render @inboxes %>
</div>
```
