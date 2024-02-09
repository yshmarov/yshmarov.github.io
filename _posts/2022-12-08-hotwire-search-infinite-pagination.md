---
layout: post
last_name: "Hotwire Turbo: Search & Infinite Scroll Pagination (Ransack + Pagy)"
author: Yaroslav Shmarov
tags: ruby-on-rails-7 hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
youtube_id: sQBRkduaezo
---

We'll build **search** and **infinite pagination** that work well together. Basically a similar UI:

![search and infinite pagination with hotwire](/assets/images/99-hotwire-search-and-infinite-pagination.png)

It's been ±9 months since I did my first post about pagination & search with Hotwire.

This is my **perfected** approach, extracted from [my latest implementation](https://github.com/yshmarov/insta2blog.com). Here's how search + infinite pagination works on my website:

![insta2blog-paginate-search.gif](/assets/images/insta2blog-paginate-search.gif)

Let's implement something similar!

### 1. Search & paginate with Pagy, without Ransack

Install pagy:

```shell
bundle add pagy
```

```ruby
# config/initializers/pagy.rb
require 'pagy/extras/countless'
```

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include Pagy::Frontend
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pagy::Backend
end
```

Search (without a gem) and pagination (with pagy) in the controller:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    users = User.order(created_at: :desc)
    users = users.where('last_name ilike ?', "%#{params[:last_name]}%") if params[:last_name].present?
    users = users.where(category: params[:category]) if params[:category].present?
    @pagy, @users = pagy_countless(users, items: 5)
  end
end
```

The index view:
- Search field is outside of turbo frame, with target `turbo_frame`; submit on input/change
- empty div that will be populated with results
- The second, inner lazy-loaded `turbo_frame` will make a request and respond with `index.turbo_stream.erb`

```ruby
# app/views/users/index.html.erb
<%= form_with url: users_path,
              method: :get,
              data: { turbo_frame: 'results' } do |form| %>
  <%= form.text_field :last_name,
                      placeholder: 'User last_name',
                      value: params[:last_name],
                      autocomplete: 'off',
                      autofocus: true,
                      oninput: 'this.form.requestSubmit()' %>
  <%= form.select :gender,
                  ['male', 'female'],
                  { include_blank: 'Category' },
                  { onchange: 'this.form.requestSubmit()' } %>
<% end %>

<%= turbo_frame_tag 'results', target: '_top', data: { turbo_action: 'advance' } do %>
  <div id="users"></div>
  <%= turbo_frame_tag 'pagination',
                      src: users_path(last_name: params[:last_name],
                                      category: params[:category],
                                      format: :turbo_stream),
                      loading: :lazy %>
<% end %>
```

`loading: :lazy` on a `turbo_frame` means that the request will perform as soon as the element becomes visible in the page. You will replace the empty div with a collection of users, and re-render the pagination turbo_stream under the added users collection:

```ruby
# app/views/users/index.turbo_stream.erb
<%= turbo_stream.append "users" do %>
  <% @users.each do |user| %>
    <%= render partial: 'users/user', locals: { user: } %>
  <% end %>
<% end %>
<% if @pagy.next.present? %>
  <%= turbo_stream.replace "pagination" do %>
    <%= turbo_frame_tag "pagination",
                        src: users_path(page: @pagy.next,
                                                   last_name: params[:last_name],
                                                   category: params[:category],
                                                   format: :turbo_stream),
                        loading: :lazy %>
  <% end %>
<% end %>
```

This should work well! However we search only by `last_name`. Let's add more advanced search: by `last_name/first_name/email`. We can easily do such a query with the **gem ransack**.

### 2. With Ransack

```shell
bundle add ransack
```

```ruby
# app/views/users/index.html.erb
<%= search_form_for @q, data: { turbo_frame: :results } do |f| %>
  <%= f.label :last_name_or_body_cont %>
  <%= f.search_field :last_name_or_body_cont, autofocus: true, autocomplete: 'off', oninput: 'this.form.requestSubmit()' %>
<% end %>
```

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    @q = User.ransack(params[:q])
    @pagy, @users = pagy_countless(@q.result(distinct: true).order(created_at: :asc), items: 2)
  end
end
```

```ruby
# app/views/users/index.html.erb
  <%= turbo_frame_tag :pagination,
                      loading: :lazy,
                      src: users_path(format: :turbo_stream, q: params[:q]) %>
```

```ruby
# app/views/users/index.turbo_stream.erb
    <%= turbo_frame_tag :pagination,
                        loading: :lazy,
                        src: users_path(format: :turbo_stream, q: params[:q], page: @pagy.next) %>
```

### 2.1. Fix Ransack `ActionController::UnfilteredParameters`

If you add `params[:q]` to an url, you might get an error `unable to convert unpermitted parameters to hash`:

![unable to convert unpermitted parameters to hash](/assets/images/unable-to-convert-unpermitted-parameters-to-hash.png)

There are 2 ways to fix it.

**Option 1:** Permit all incoming query params `params[:q]&.permit!`:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    @q = User.ransack(params[:q]&.permit!)
    @pagy, @users = pagy_countless(@q.result(distinct: true).order(created_at: :asc), items: 2)
  end
end
```

However this can be considered not very safe, because a malicious actor could try to dig sensitive data this way.

**Option 2:** safer approach.

Allow an unsafe hash input in the views with `params[:q]&.to_unsafe_h`:

```
users_path(format: :turbo_stream, q: params[:q]&.to_unsafe_h, page: @pagy.next)
```

However in the controller you can explicitly state the query params that you want to enable with `params.permit`. In this case, we would also need to permit `format`:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    search_params = params.permit([:format, q: [:s,:last_name_or_body_cont]], :page)
    @q = User.ransack(search_params[:q])
    @pagy, @users = pagy_countless(@q.result(distinct: true).order(created_at: :asc), items: 2)
  end
end
```

Final result:

![ransack-pagy.gif](/assets/images/ransack-pagy.gif)

That's it! 🎉🥳🍾
