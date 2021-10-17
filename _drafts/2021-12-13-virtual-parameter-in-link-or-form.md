---
layout: post
title: "Pass a virtual parameter in a form or url"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails params attr_accessor
thumbnail: /assets/thumbnails/url.png
---

Based on a virtual attibute
* Validate
* Run callbacks
* Display


You might want to a model to `behave differently` by passing `virtual parameter` in the url or in a form.
*`behave differently` - for example, different validations
*`virtual parameter` - value that is not assiciated with a model

### Example 1

* you have 2 links in a view with same url, but different params:

#app/views/static_pages/landing_page.html.erb
```ruby
link_to 'Create a public inbox', new_inbox_path(category: :public)
#=> localhost:3000/inboxes/new?&category=public
# params[:category]
#=> public

link_to 'Create a private inbox', new_inbox_path(category: :private)
#=> localhost:3000/inboxes/new?&category=private
# params[:category]
#=> private
```

* you might not want to add `category` to your database, while still changing something in the model when passing category in the params

```ruby
<%= form_with(model: inbox) do |form| %>
  <%= form.text_field :name %>
  <%= form.select :category, Inbox::CATEGORIES, include_blank: true %>

  <%= form.hidden_field :type, value: params[:type] %>
  <%= form.hidden_field :full_update, value: true %>
  <%= form.hidden_field :full_update, value: 'maybe' %>
  <%= inbox.category.present? %>
  <%= inbox.category %>

  <%= form.submit %>
<% end %>
```

####

#console
```sh
rails g scaffold inbox name
```

* whitelist the param in the controller

#app/controllers/inboxes_controller.rb
```ruby
class InboxesController < ApplicationController
  def inbox_params
    params.require(:inbox).permit(:name, :category)
  end
end
```

* add the param as an `attr_accessor` in the model

#app/models/inbox.rb
```ruby
class Inbox < ApplicationRecord

  CATEGORIES = [:blog, :private, :qna, :leads]

  attr_accessor :category
end
```



link_to 'New form', new_inbox_path(new_form: true)
params[:new_form]
