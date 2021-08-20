---
layout: post
title: "Export from database table to Excel Workbook. Level 1"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails export excel xls xlsx download
thumbnail: /assets/thumbnails/xlsx.png
---

Use the [gem caxlsx](https://github.com/caxlsx/caxlsx_rails) to download and format data into XLSX.

* XLS - proprietary Microsoft Excel format
* XLSX - free format

Gemfile

```ruby
gem 'caxlsx'
gem 'caxlsx_rails'
```

/app/controllers/posts_controller.rb

```ruby
  def index
    respond_to do |format|
      format.html do
        @posts = Post.order(created_at: :desc)
      end
      format.xlsx do
        @posts = Post.all
        render xlsx: 'posts', template: 'posts/whatever'
        # response.headers['Content-Disposition'] = 'attachment; filename="all_posts_that_we_have.xlsx"'
        # render xlsx: 'posts', template: 'posts/whatever', filename: "my_posts.xlsx", disposition: 'inline', xlsx_created_at: 3.days.ago, xlsx_author: "Elmer Fudd"
      end
    end
  end
```

/app/views/posts/whatever.xlsx.axlsx

```ruby
wb = xlsx_package.workbook

wb.add_worksheet(name: "Post") do |sheet|
  sheet.add_row ['name', 'creation date']
  @posts.each do |post|
    sheet.add_row [post.name, post.created_at]
  end
end
```

any view:

```ruby
= link_to 'xlsx', posts_path(format: :xlsx), target: :_blank
```

I will be adding more info here later on.

Here is a more detailed article (that initially inspired me): 
[https://www.sitepoint.com/generate-excel-spreadsheets-rails-axlsx-gem/](https://www.sitepoint.com/generate-excel-spreadsheets-rails-axlsx-gem/)
