---
layout: post
title: "Mass update selected records"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails bulk-actions mass-params
thumbnail: /assets/thumbnails/checkboxes.png
---

Sometime users want to select multiple records and perform a bulk action on them.

Typical bulk actions are `delete`/`assign`/`change_status`/`bookmark`.

In this example we will allow a user to select multiple records and change their status between `active`/`disabled`.

![checkbox-bulk-update.gif](/assets/images/checkbox-bulk-update.gif)

Initial app setup:

```ruby
# terminal
bundle add faker
rails g scaffold user email status
rails db:migrate
rails c
10.times { User.create(email: Faker::Internet.email, status: [:active, :disabled].sample) }
```

Enum status to easily get all active/disabled users, use a bang method to mark user `active`/`disabled`:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  enum status: { active: 'active', disabled: 'disabled' }
  # User.active
  # User.first.active!
end
```

Add a route to handle bulk actions:

```ruby
# config/routes.rb
  resources :users do
    collection do
      patch :bulk_action # bulk_action_users_path
    end
  end
```

Add a form with a unique `id` and route it to `bulk_action_users_path`.

`data: {controller: "form-reset"})` - so that old selected checkboxes are not checked on page refresh.

**IMPORTANT** Different form buttons can send a different param to the controller. Based on this you will be able to handle different bulk actions
* `form.button type: :submit, value: :active` => `params[:button] == 'active'`
* `form.submit "disabled"` => `params[:commit] == "disabled"`

```ruby
# app/views/users/index.html.erb
<p style="color: green"><%= notice %></p>

<h1>Users</h1>
<%= @users.active.count %>
<%= @users.disabled.count %>

<%= form_with(url: bulk_action_users_path, id: :bulk_actions_form, method: :patch, data: {controller: "form-reset"}) do |form| %>
  <%#= form.submit "active" %>
  <%#= form.submit "disabled" %>
  <%= form.button type: :submit, value: :active do %>
    Activate selected
  <% end %>
  <%= form.button type: :submit, value: :disabled do %>
    Disable selected
  <% end %>
<% end %>

<%= render partial: "user", collection: @users %>
```

Add a `check_box_tag` to the user partial:
* `user_ids[]` - on form submit we will pass `params(:user_ids)`
* `multiple: true` - allow multiple items to be checked
* `form: :bulk_actions_form` - it will submit to the above form

```ruby
# app/views/users/_user.html.erb
<div id="<%= dom_id user %>">
  <%= check_box_tag "user_ids[]",
                    user.id,
                    nil,
                    {
                      multiple: true,
                      form: :bulk_actions_form,
                      checked: false
                    } %>
  <%= user.status %>
  <%= user.email %>
</div>
```

Finally, either `disable` or `activate` selected users based on which form button was clicked:

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def bulk_action
    # find users
    @selected_users = User.where(id: params.fetch(:user_ids, []).compact)
    # update
    @selected_users.update_all(status: :active) if mass_active?
    @selected_users.each { |u| u.disabled! } if mass_disabled?
    # redirect
    flash[:notice] = "#{@selected_users.count} users: #{params[:button]}"
    redirect_to action: :index
  end

  private

  def mass_active?
    params[:button] == 'active'
    # params[:commit] == "active"
  end

  def mass_disabled?
    params[:button] == 'disabled'
    # params[:commit] == "disabled"
  end
end
```

Final result:

![checkbox-bulk-update.gif](/assets/images/checkbox-bulk-update.gif)
