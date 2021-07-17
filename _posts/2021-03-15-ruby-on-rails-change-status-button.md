---
layout: post
title: "Button to update status attribute of a table"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails polymorphism polymorphic-associations
thumbnail: /assets/thumbnails/button-thumbnail.png
---

Mission: add buttons to change the `status` of a `task`

![change-status.gif](/assets/images/change-status.gif)

HOWTO:

migration - add `status` column to `tasks`
```
add_column :tasks, :status, :string, null: false, default: "planned"
```
task.rb - list available statuses
```
  validates :status, presence: true
  STATUSES = [:planned, :progress, :done]
```
tasks_controller.rb - add action to change status
```
  def change_status
    @task = Task.find(params[:id])
    if params[:status].present? && Task::STATUSES.include?(params[:status].to_sym)
      @task.update(status: params[:status])
    end
    redirect_to @task, notice: "Status updated to #{@task.status}"
  end
```
routes.rb
```
  resources :tasks do
    member do
      patch :change_status
    end
  end
```
tasks/show.html.erb
```
  <% Task::STATUSES.each do |status| %>
    <%= link_to change_status_task_path(@task, status: status), method: :patch do %>
      <%= status %>
    <% end %>
  <% end %>
```
or with a block
```
  <% Task::STATUSES.each do |status| %>
    <%= link_to_unless task.status.eql?(status.to_s), status, change_status_task_path(task, status: status), method: :patch %>
  <% end %>
```
