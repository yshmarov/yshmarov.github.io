---
layout: post
title: "Tiny Tip: URL and link helpers."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails request-params url_for link_to
thumbnail: /assets/thumbnails/url.png
---

```ruby
<%= request.path %>
<%# /inboxes %>

<%= request.fullpath %>
<%# /inboxes?q%5Bs%5D=messages_count+asc  %>

<%= request.url %>
<%# localhost:3000/inboxes?q%5Bs%5D=messages_count+asc  %>
```

### 1.1 URL params are mighty! Use them! Some helpers:

* get current controller name & action name

```
<%= controller_name %>
<%= action_name %>
```

* clean way to link to current path without helpers

```erb
<%= link_to "Refresh", controller: controller_name, action: action_name %>
```

* even cleaner way to current path

<%= link_to "Refresh", request.path %>

* check if a controller/action name equals ...

```ruby
controller_name.eql?('x')
action_name.eql?('y')
```

* see if we are now on a specific path

```ruby
<%= current_page?(root_path) %>
```

* get query_parameters for an url
* `localhost:3000/users?created_at=asc` would return `{"created_at"=>"asc"}`

```ruby
<%= request.query_parameters %>
<%= request.query_parameters.empty? %>
```

now you can do

```ruby
<%= link_to 'clear search', request.path if request.query_parameters.any? %>
```

* see all params that are applied to current URL

```ruby
<%= params %>
```

* controller and action params are always present in a request
* BAD hacky way to see if any OTHER params are present:
* better use the above `request.query_parameters.present?`

```ruby
<%=(params.keys - ['controller'] - ['action']).present? %>
```

* see if a particular params is present (true / false)

```ruby
<%= params.key?(:messages_count) %>
```

* display the value of a param (if present)

```ruby
params[:messages_count].presence
```

### 1.2 Request-based manipulations 

* link_to current url via `request` with removing params

```erb
<%= link_to "Refresh", request.params.slice("query", "filter", "sort") %>
```

* moving the above into a helper

#app/helpers/application_helper.rb
```ruby
module ApplicationHelper
  def current_page_params
    # remove query params that you might have
    request.params.slice("query", "filter", "sort")
  end
end
```

```erb
<%= link_to "Refresh with helper", current_page_params %>
```

* add params to above helper

```erb
<%= link_to "with foo", current_page_params.merge(foo: true) %>
```

* ways to get link to current url


### 2. Link helpers

* basic link to unless

```ruby
<%= link_to_unless_current 'Inboxes', inboxes_path %>
```

* link to controller & action

```ruby
<%= link_to "Login",  controller: "user", action: "login" %>
```

* link to with params
```ruby
<%= link_to "Profile", controller: "profiles", action: "show", id: @profile %>
# => <a href="/profiles/show/1">Profile</a>
```

* here, links are active only for admin user:

```ruby
<% @posts.each do |post| %>
  <%= link_to_if @user.admin?, post.title, manage_post_path(post) %>
<% end %>
```

* here, links are active if we are not on `controller=inboxes`, `action=index`

```ruby
<%= link_to_unless controller_name.eql?('inboxes') && action_name.eql?('index'), 'Inboxes', inboxes_path %>
```

* here, links are active if we are not on `controller=inboxes`

```ruby
<%= link_to_unless controller_name.eql?('inboxes'), 'Inboxes', inboxes_path %>
```

* link to either `inboxes/index` or `inboxes/new`
```ruby
<%=
  link_to_unless_current("New inbox", { controller: "inboxes", action: "new" }) do
    link_to("SCOTS", { controller: "inboxes", action: "index" })
  end
%>
```

This is initially inspired by [https://boringrails.com/tips/rails-link-to-unless-current](https://boringrails.com/tips/rails-link-to-unless-current)
