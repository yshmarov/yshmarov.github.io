---
layout: post
title: "#8 Hotwire Turbo: Tabbed content with Turbo Streams"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

![turbo-streams-tabs](/assets/images/turbo-streams-tabs.gif)

You can achieve adding tabbed content with both, turbo frames and turbo streams.

Here's how you can do it with turbo streams.

#### 0. Initial setup

* create some models and relationships

console
```ruby
rails g resource project name
rails g model task name project:references
rails g model comment name project:references
rails db:migrate
```

project.rb
```ruby
  has_many :tasks
  has_many :comments
```

* add some dummy data

console
```ruby
rails c
Project.create name: SecureRandom.hex
Project.first.tasks << Task.create(name: SecureRandom.hex)
Project.first.tasks << Task.create(name: SecureRandom.hex)
Project.first.comments << Comment.create(name: SecureRandom.hex)
Project.first.comments << Comment.create(name: SecureRandom.hex)
```

* display a project

app/controllers/projects_controller.rb
```ruby
class ProjectsController < ApplicationController
  before_action :set_project

  def show
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end
end
```

* partials for displaying comments and tasks

app/views/projects/_comments.html.erb
```ruby
Comments for
<%= project.name %>
<br>
<% comments.each do |comment| %>
  <%= comment.id %>
  <%= comment.name %>
  <br>
<% end %>
```

app/views/projects/_tasks.html.erb
```ruby
Tasks for 
<%= project.name %>
<br>
<% tasks.each do |task| %>
  <%= task.id %>
  <%= task.name %>
  <br>
<% end %>
```

* display the partials in the project view

app/views/projects/show.html.erb
```ruby
<%= @project.id %>
<hr>
<%= render partial: 'projects/tasks', locals: { project: @project, tasks: @project.tasks } %>
<hr>
<%= render partial: 'projects/comments', locals: { project: @project, comments: @project.comments } %>
```

#### 1. Dropdowns with Turbo Streams.

* you can not use GET requests with turbo streams (by design)
* create a route that will respond only with a turbo stream

#config/routes.rb
```ruby
  resources :projects do
    member do
      post :dropdowns
    end
  end
```

* create a controller action for the new route
* find target, replace it with a partial with some locals
* sure, you don't have to pass both tasks and comments in the same locals. feel free to add some logic to pass either comments, or tasks (homework!)

#app/controllers/projects_controller.rb
```ruby
  def dropdowns
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: 
          turbo_stream.update('dropdown_target', partial: "projects/#{params[:type]}", locals: { tasks: @project.tasks, comments: @project.comments, project: @project })
      end
    end
  end
```

* create links to each partial (tasks and comments)
* highlight current link. But [you can not use `current_page` with non-get requests](https://stackoverflow.com/questions/9749807/rails-current-page-fails-when-method-is-post)

app/views/projects/_tabs.html.erb
```ruby
<% [:tasks, :comments].each do |type| %>
  <%= button_to dropdowns_project_path(@project, type: type), method: :post do %>
    <%= content_tag :span, type, style: "#{"font-weight: bold" if request.fullpath.eql?(dropdowns_project_path(@project, type: type))}" %>
  <% end %>
<% end %>
```

* add a target for the turbo_stream
* add the tabs

app/views/projects/show.html.erb
```ruby
<div id="dropdown_target">
  <%= render partial: 'projects/tabs' %>
  this will be replaced by tasks or comments partials
</div>
```

* add the tabs in the tabbed content partials, as the initial tabs will be replaced.
* we want the ininital tabs to be replaced because of highlighting path to current page.

app/views/projects/_comments.html.erb
```diff
++ <%= render partial: 'projects/tabs' %>
...
```

app/views/projects/_comments.html.erb
```diff
++ <%= render partial: 'projects/tabs' %>
...
```

#### 2. Improved Dropdowns with separate actions

* in case you don't want to do the homework from above ;)

app/config/routes.rb
```diff
  resources :projects do
    member do
++    post :comments
++    post :tasks
--      post :dropdowns
    end
  end
```

```ruby
  def comments
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: 
          turbo_stream.update('dropdown_target', 
                              partial: "projects/comments",
                              locals: { comments: @project.comments, project: @project })
      end
    end
  end

  def tasks
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: 
          turbo_stream.update('dropdown_target', 
                              partial: "projects/tasks",
                              locals: { tasks: @project.tasks, project: @project })
      end
    end
  end
```

```ruby
<%= button_to tasks_project_path(@project), method: :post do %>
  <%= content_tag :span, "Tasks", style: "#{"font-weight: bold" if request.fullpath.eql?(tasks_project_path(@project))}" %>
<% end %>

<%= button_to comments_project_path(@project), method: :post do %>
  <%= content_tag :span, "Comments", style: "#{"font-weight: bold" if request.fullpath.eql?(comments_project_path(@project))}" %>
<% end %>
```

#### 3. Bonus: Default open tab

* you can just render one of the partials in the target by default
* of course, you would have to alter the `_tabs` partial for `tasks` to be current both for base url and url with params

app/views/projects/show.html.erb
```ruby
<div id="dropdown_target">
  <%= render partial: 'projects/tasks', locals: { project: @project, tasks: @project.tasks } %>
  this will be replaced by tasks or comments
</div>
```

Consideration: you might want to have an URL to be also changed/be available to something like `/projects/1/tasks` or `projects/1/comments`. This is not available by default so 

****

That's it!

Althrough, it might seem unnatural to use non-get requests for tabbed content.

We can achieve a similar result with turbo frames.
