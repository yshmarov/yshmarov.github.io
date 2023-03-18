---
layout: post
title: "Trello Clone: drag, drop and save changes with Ranked-Model, SortableJs and RequestJs"
author: Yaroslav Shmarov
tags: trello requestjs sortable-js request-js ranked-model acts_as_list sort
thumbnail: /assets/thumbnails/trello.png
---

The goal here is to create a board like Trello, where we have Lists and Tasks within lists.

We should be able to use drag-and-drop to:
- change order of Tasks within a List
- move Tasks between lists
- change order of Lists
- save changes

Here's a demo of what final solution will look like:

![trello-drag-drop-save.gif](/assets/images/119-trello-drag-drop-save.gif)

### 1. Initial setup and gem Ranked-model

[ranked-model](https://github.com/brendon/ranked-model) is superior to [acts_as_list](https://github.com/brendon/acts_as_list). You can check the gems docs to learn why.

```shell
# terminal
bundle add ranked-model
rails g migration AddRowOrderToListsAndTasks
```

These should allow null values

```ruby
class AddRowOrderToListsAndTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :lists, :row_order, :integer
    add_column :tasks, :row_order, :integer
  end
end
```

Add RankedModel to List

```ruby
# app/models/list.rb
  validates :name, presence: true
  has_many :tasks

  include RankedModel
  ranks :row_order
```

Add RankedModel to Task. Use `with_same` to correctly calculate row_order **within a list**

```ruby
# app/models/task.rb
  validates :name, presence: true
  belongs_to :list

  include RankedModel
  ranks :row_order, with_same: :list_id
```

### 2. Install [rails/request.js](https://github.com/rails/requestjs-rails)

It will allow us to make HTTP requests from our Stimulus controllers into our rails controllers

```shell
bundle add requestjs-rails
./bin/rails requestjs:install
```

### 3. Install [sortable-js](https://github.com/SortableJS/Sortable)

```shell
./bin/importmap pin stimulus-sortable sortablejs
```

This stimulus controller will:
- initialize SotrableJS on an element and allow to sort it's children
- send a request to a selected URL within your app with the params of a new `row_order_position` of an element (`newIndex`), and if the element was moved to another parent list - with a parent id (`sortableListId`)
- a `group` param that enables us to move tasks within lists (should be set on tasks <ul>)

```js
import { Controller } from "@hotwired/stimulus"
import { put } from "@rails/request.js";
import Sortable from 'sortablejs';

// Connects to data-controller="sortable"
export default class extends Controller {
  static values = {
    group: String
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      onEnd: this.onEnd.bind(this),
      group: this.groupValue
    });
  }

  onEnd(event) {
    var sortableUpdateUrl = event.item.dataset.sortableUpdateUrl
    var newIndex = event.newIndex
    var sortableListId = event.to.dataset.sortableListId
    console.log(sortableUpdateUrl)
    console.log(newIndex)
    console.log(sortableListId)
    put(sortableUpdateUrl, {
      body: JSON.stringify({row_order_position: newIndex, list_id: sortableListId}),
    })
  }
}
```

### 4. Controller setup to sort tasks and lists

`sortableUpdateUrl` will have to lead to either `sort_task_path(task)` or `sort_list_path(list)`

```ruby
# config/routes.rb
  resources :tasks do
    member do
      put :sort
    end
  end
  resources :lists do
    member do
      put :sort
    end
  end
```

`.rank(:row_order)` sorts elements by their rank (as opposed to `created_at` or `name`).

Through in the database we store `row_order`, the update param should be `row_order_position` according to the RankedModel docs.

```ruby
# app/controllers/lists_controller.rb
  def index
    @lists = List.rank(:row_order)
  end

  def sort
    @list = List.find(params[:id])
    @list.update(row_order_position: params[:row_order_position])
    head :no_content
  end

  def list
    @tasks = @list.tasks.rank(:row_order)
  end
```

To update the task we will also need the `list_id`, because tasks can be moved between lists.

```ruby
# app/controllers/tasks_controller.rb
  def sort
    @task = Task.find(params[:id])
    @task.update(row_order_position: params[:row_order_position], list_id: params[:list_id])
    head :no_content
  end
```

### Finally, integrate the stimulus controller into the views:

Initialize sortable stimulus controller with `data-controller="sortable"`.

Set the update path that should be triggered when an item gets sorted with `data-sortable-update-url="<%= sort_list_path(list) %>"`.

```html
<!-- app/views/lists/index.html.erb -->
<div id="lists">
  <ul data-controller="sortable" style="display:flex;">
    <% @lists.each do |list| %>
      <li data-sortable-update-url="<%= sort_list_path(list) %>" style="border:solid; width: 400px">
        <%= render list %>
      </li>
    <% end %>
  </ul>
</div>
```

Within a sortable list we have sortable tasks. 

If you allow moving tasks within lists, `data-sortable-group-value="tasks"` specifies that **tasks** can be moved only to lists that have the same group name.

`data-sortable-id="<%= list.id %>"` will let your stimulus controller access the ID of the list to which the item was moved.

```html
<!-- app/views/lists/_list.html.erb -->
<div id="<%= dom_id list %>">
  <strong>List:</strong>
  <%= list.id %>
  <%= list.name %>
  <%= list.row_order %>

  <ul data-controller="sortable" data-sortable-group-value="tasks" data-sortable-list-id="<%=list.id%>">
    <% list.tasks.rank(:row_order).each do |task| %>
      <li data-sortable-id="<%= task.id %>" data-sortable-update-url="<%= sort_task_path(task) %>">
        <%= render task %>
      </li>
    <% end %>
  </ul>
</div>
```

Just in case, here's a very basic task partial:

```html
<!-- app/views/tasks/_task.html.erb -->
<div id="<%= dom_id task %>">
    <strong>Task:</strong>
    <%= task.name %>
    <%= task.row_order %>
</div>
```

Final result:

![trello-drag-drop-save.gif](/assets/images/119-trello-drag-drop-save.gif)

And that's it! Now we have advanced sorting functionality for a very small price.
