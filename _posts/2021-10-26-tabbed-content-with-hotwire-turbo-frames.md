---
layout: post
title: "#9 Hotwire Turbo: Tabbed content with Turbo Frames"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo
thumbnail: /assets/thumbnails/turbo.png
---

![turbo-frames-tabs](assets/images/turbo-frames-tabs.gif)

In the previous post we did tabbed content with turbo streams by replacing a DOM ID with a template served by a POST request.

Now we will add tabbed content functionality with turbo frames.

Use the boilerplate functionality from the previous post.

#### 1. Turbo Frames. Separate controller actions for each dropdown.

* for turbo frames, you can use GET routes without any problems.

app/config/routes.rb
```ruby
  resources :projects do
    member do
      get :comments
      get :tasks
    end
  end
```

* respond with html
* you can render either `partial` or `template`. I just prefer partial here. Does not matter much.
* `turbo_frame_request?` - to make this `format.html` available ONLY via turbo request, not as a separate page
* `else redirect` - if someone tries to open a tab in a new tab

[`turbo_frame_request` source code](https://github.com/hotwired/turbo-rails/blob/main/app/controllers/turbo/frames/frame_request.rb#L21){:target="blank"}

app/controllers/projects_controller.rb
```ruby
  def comments
    if turbo_frame_request?
      respond_to do |format|
        format.html { render partial: 'projects/comments',
          locals: { comments: @project.comments, project: @project }}
      end
    else
      redirect_to @project, alert: "Not allowed"
    end
  end

  def tasks
    if turbo_frame_request?
      respond_to do |format|
        format.html { render partial: 'projects/tasks',
          locals: { tasks: @project.tasks, project: @project }}
      end
    else
      redirect_to @project, alert: "Not allowed"
    end
  end
```

* create a partial with links
* request.url - just for you to see the current url that is being rendered inside the frame ;)
* style - to highlight the current link

app/views/projects/_tabs.html.erb
```ruby
<%= request.url %>
<br>
<%= link_to "Tasks", tasks_project_path(@project),
      style: "#{"font-weight: bold" if current_page?(tasks_project_path(@project))}" %>
<%= link_to "Comments", comments_project_path(@project),
      style: "#{"font-weight: bold" if current_page?(comments_project_path(@project))}" %>
```

* create a turbo frame. give it a name
* render the partial with tabs inside

app/views/projects/show.html.erb
```ruby
<%= turbo_frame_tag 'frame_dropdowns' do %>
  <%= render partial: "projects/tabs" %>
<% end %>
```

* wrap content of `tasks` and `comments` into a `turbo_frame_tag`
* don't forget to render the `_tabs` partial

app/views/projects/_tasks.html.erb
```ruby
<%= turbo_frame_tag 'frame_dropdowns' do %>
  <%= render partial: 'projects/tabs' %>
  <h3>
  Tasks for project #
  <%= project.id %>
  </h3>
  <ul>
  <% tasks.each do |task| %>
    <li>
      <%= task.id %>
      <%= task.name %>
    </li>
  <% end %>
  </ul>
<% end %>
```

app/views/projects/_comments.html.erb
```ruby
<%= turbo_frame_tag 'frame_dropdowns' do %>
  <%= render partial: 'projects/tabs' %>
  <h3>
  Comments for project #
  <%= project.id %>
  </h3>
  <ul>
  <% comments.each do |comment| %>
    <li>
      <%= comment.id %>
      <%= comment.name %>
    </li>
  <% end %>
  </ul>
<% end %>
```
#### 2. Default open tab

app/views/projects/show.html.erb
```ruby
<%= turbo_frame_tag 'frame_dropdowns' do %>
  <%= render partial: "projects/tasks", locals: { project: @project, tasks: @project.tasks } %>
<% end %>
```

#### 3. Using template variants to respond only with a turbo frame

* use template, not partial
* if request is done by a turbo frame, respond with the template variant for turbo frame. [More about Rails layout variants](https://guides.rubyonrails.org/layouts_and_rendering.html#the-variants-option){:target="blank"}

```ruby
class ProjectsController < ApplicationController
  before_action :set_project
  before_action :turbo_frame_request_variant

  def show
  end

  def comments
    respond_to do |format|
      format.html { render template: 'projects/comments', 
                           locals: { comments: @project.comments, project: @project }}
    end
  end

  def tasks
    respond_to do |format|
      format.html { render template: 'projects/tasks', 
                           locals: { tasks: @project.tasks, project: @project }}
    end
  end

  private

  def turbo_frame_request_variant
    request.variant = :turbo_frame if turbo_frame_request?
  end

  def set_project
    @project = Project.find(params[:id])
  end
end
```

* rename partials to templates, add `+turbo_frame` estention to the templates to respond with them
```diff
-- _comments.html.erb
-- _tasks.html.erb
++ comments.html+turbo_frame.erb
++ tasks.html+turbo_frame.erb
```

* Now, when someoone tries to open a new tab, they will get a `Template is missing` error.

#### Conclusion:

* Rendering tabbed content with turbo frames feels more natural (than with STREAMS)
* Frames use GET request
* Streams use POST, PATCH, UPDATE, DELETE requests
* Streams and Frames can exist independently from each other
