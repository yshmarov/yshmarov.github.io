---
layout: post
title: "Custom scaffold templates"
author: Yaroslav Shmarov
tags: railsbytes rubidium generators templates scaffolds rails ruby-on-rails-6
thumbnail: /assets/thumbnails/script.png
---

dependencies: `simple_form`, `bootstrap`

run this [script](/script-custom-scaffold-templates.txt) in your terminal to add bootstrap scaffold templates to your app:
```
rails app:template LOCATION="{{ site.url }}/script-custom-scaffold-templates.txt"
```
regenerate scaffold views for existing model based on attributes:
```
rails g erb:scaffold User firstname lastname
```

Here's how bootstrap scaffold templates erb files can look:

lib/templates/erb/scaffold/_form.html.erb
```
<%# frozen_string_literal: true %>
<%%= simple_form_for(@<%= singular_table_name %>) do |f| %>
  <%%= f.error_notification %>
  <%%= f.error_notification message: f.object.errors[:base].to_sentence if f.object.errors[:base].present? %>

  <div class="form-inputs">
  <%- attributes.each do |attribute| -%>
    <%%= f.<%= attribute.reference? ? :association : :input %> :<%= attribute.name %> %>
  <%- end -%>
  </div>

  <div class="form-actions">
    <%%= f.button :submit %>
  </div>
<%% end %>
```
lib/templates/erb/scaffold/index.html.erb
```
<h3>
  <div class="text-center">
    <%= plural_table_name.capitalize %>
    <div class="badge badge-info">
      <%%= @<%= plural_table_name%>.count %>
    </div>
    <%%= link_to "New <%= singular_table_name %>", new_<%= singular_table_name %>_path, class: 'btn btn-primary' %>
  </div>
</h3>
<div class="table-responsive">
  <table class="table table-striped table-bordered table-hover table-sm table-light shadow">
    <thead>
      <tr>
        <th>Id</th>
    	  <% attributes.each do |attribute| %>
        <th><%= attribute.human_name %></th>
        <% end %>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <%% @<%= plural_table_name%>.each do |<%= singular_table_name %>| %>
        <%%= content_tag :tr, id: dom_id(<%= singular_table_name %>), class: dom_class(<%= singular_table_name %>) do %>
          <td><%%= link_to <%= singular_table_name %>.id, <%= singular_table_name %> %></td>
          <% attributes.each do |attribute| %>
            <td><%%= <%= singular_table_name %>.<%= attribute.name %> %></td>
          <% end %>
          <td>
            <%%= link_to 'Edit', edit_<%= singular_table_name %>_path(<%= singular_table_name %>), class: 'btn btn-sm btn-warning' %>
            <%%= link_to 'Destroy', <%= singular_table_name %>, method: :delete, data: { confirm: 'Are you sure?' }, class: 'btn btn-sm btn-danger' %>
          </td>
        <%% end %>
      <%% end %>
    </tbody>
  </table>
</div>
```
lib/templates/erb/scaffold/show.html.erb
```
<div class="card shadow">
  <div class="card-header">
    <h4>
      <%= singular_table_name.capitalize %>
    </h4>
  </div>
  <div class="card-body">
    <% attributes.each do |attribute| %>
        <strong><%= attribute.human_name %>:</strong>
        <%%= @<%= singular_table_name %>.<%= attribute.name %> %>
    <% end %>
  </div>
  <div class="card-footer">
    <%%= link_to 'Edit', edit_<%= singular_table_name %>_path(@<%= singular_table_name %>) %> |
    <%%= link_to 'Back', <%= index_helper %>_path %>
  </div>
</div>
```
lib/templates/erb/scaffold/new.html.erb
```
<div class="card shadow">
  <div class="card-header">
    <h4>
      New
      <%= singular_table_name.capitalize %>
    </h4>
  </div>
  <div class="card-body">
    <%%= render 'form', <%= singular_table_name %>: @<%= singular_table_name %> %>
  </div>
  <div class="card-footer">
    <%%= link_to 'Back', <%= index_helper %>_path %>
  </div>
</div>
```
lib/templates/erb/scaffold/edit.html.erb
```
<div class="card shadow">
  <div class="card-header">
    <h4>
      Edit
      <%= singular_table_name.capitalize %>
    </h4>
  </div>
  <div class="card-body">
    <%%= render 'form', <%= singular_table_name %>: @<%= singular_table_name %> %>
  </div>
  <div class="card-footer">
    <%%= link_to 'Show', @<%= singular_table_name %> %> |
    <%%= link_to 'Back', <%= index_helper %>_path %>
  </div>
</div>
```

Inspiration: 

* [railsbytes.com](https://railsbytes.com/public/templates/VqqsG8)
* [web-crunch.com](https://web-crunch.com/posts/how-to-create-custom-scaffold-templates-in-ruby-on-rails)
* [stackoverflow.com](https://stackoverflow.com/questions/8114866/create-ruby-on-rails-views-only-after-controllers-and-models-are-already-creat)