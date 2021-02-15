---
layout: post
title: "Custom scaffold templates"
author: Yaroslav Shmarov
tags: railsbytes rubidium generators templates scaffolds rails ruby-on-rails-6
thumbnail: /assets/thumbnails/script.png
---

Add sexy `simple_form` & `bootstrap` styling for your scaffolds by default.

Example of final result:

![custom-scaffold-templates-result.png](/assets/custom-scaffold-templates/custom-scaffold-templates-result.png)

run this [script](/script-custom-scaffold-templates.txt){:target="blank"} in your terminal to add bootstrap scaffold templates to your app:
```
rm ./lib/templates/erb/scaffold/_form.html.erb

rails app:template LOCATION="{{ site.url }}/script-custom-scaffold-templates.txt"
```

***

Regenerating scaffold views for existing model based on attributes:
```
rails g erb:scaffold Post title content
```

Here's how bootstrap scaffold templates erb files can look:

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

Inspiration: 

* [official rails docs](https://github.com/rails/rails/blob/main/railties/lib/rails/generators/erb/scaffold/templates/index.html.erb.tt){:target="blank"}
* [railsbytes.com](https://railsbytes.com/public/templates/VqqsG8){:target="blank"}
* [web-crunch.com](https://web-crunch.com/posts/how-to-create-custom-scaffold-templates-in-ruby-on-rails){:target="blank"}
* [stackoverflow.com](https://stackoverflow.com/questions/8114866/create-ruby-on-rails-views-only-after-controllers-and-models-are-already-creat){:target="blank"}