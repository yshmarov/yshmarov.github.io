---
layout: post
title: Generate PDF with gem wicked_pdf 
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails pdf
thumbnail: /assets/thumbnails/pdf.png
---

Assuming you have a table `posts`.

Gemfile

```
gem 'wicked_pdf'
gem "wkhtmltopdf-binary", group: :development
gem "wkhtmltopdf-heroku", group: :production
```

config/initializers/wicked_pdf.rb

```
# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

WickedPdf.config ||= {}
WickedPdf.config.merge!({
  layout: "pdf.html.erb",
  orientation: "Landscape",
  lowquality: true,
  zoom: 1,
  dpi: 75
}) 
```

app/views/layouts/pdf.html.erb

```
<!DOCTYPE html>
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <meta charset="utf-8"/>
    <%= wicked_pdf_stylesheet_link_tag "pdf" %>
  </head>
  <body onload="number_pages">
    <div id="header">
      <!--= wicked_pdf_image_tag 'thumbnail.png', height: "30", width: "auto"
      -->
    </div>
    <div id="content">
      <%= yield %>
    </div>
  </body>
</html>
```

app/controllers/posts_controller.rb

```
  def index
    @posts = Post.all.order(created_at: :desc)
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Posts",
               page_size: "A4",
               template: "posts/post.pdf.erb"
      end
    end
  end
```

app/views/posts/index.html.erb

```
     <%= link_to "PDF", posts_path(format: :pdf), class: 'btn btn-primary' %>
```

app/views/posts/post.pdf.erb

```
Date of extract: 
<%= Date.today %>
<br>

Posts count:
<%= @posts.count %>
<br>

<table style="width:100%">
  <thead>
    <tr>
      <th>id
      <th>title</th>
      <th>content</th>
    </tr>
  </thead>
  <tbody>
    <% @posts.each do |post| %>
      <%= content_tag :tr, id: dom_id(post), class: dom_class(post) do %>
        <td><%= post.id %></td>
        <td><%= post.title %></td>
        <td><%= post.content %></td>
      <% end %>
    <% end %>
  </tbody>
</table> 
```

app/assets/stylesheets/pdf.scss

```
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
} 
```

That's it!