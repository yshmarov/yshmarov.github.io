---
layout: post
title: "Export CSV from Rails"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails export excel xls xlsx csv download
thumbnail: /assets/thumbnails/xlsx.png
youtube_id: E_8BBAvVCqw
---

In a
[previous article]({% post_url 2021-08-20-export-from-database-to-excel %}){:target="blank"}
we **exported** data from a Rails database to XLSX using a gem.

We can export to CSV without any external gems, because Ruby has an in-built CSV processor.

![export-csv-rails](/assets/images/export-csv-rails.gif)

I see two good approaches to generating CSV:

### 1. `*.csv.erb` template without `Ruby::CSV` (elementary approach)

A rails app can respond to format csv by default.

We can create a template with some data formatted as CSV lines and have a link to download the rendered page.

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html
      format.csv
    end
  end
```

```ruby
# app/views/users/index.hmtl.erb
<%= link_to "CSV export", users_path(format: :csv), download: ['Users', Date.today].join(' ') %>
```

```ruby
# app/views/users/index.csv.erb

# send all fields
<% fields = [:id, :email, :last_name] %>
<%= fields.map(&:to_s).join(";") %>
<% @users.each do |user| %>
<%= fields.map { |field| user[field].to_s }.join(";") %>
<% end %>

# or send selected fields
<%= User.column_names.map(&:to_sym).join(";") %>
<% @users.each do |user| %>
<%= user.attributes.values_at(*User.column_names).join(";") %>
<% end %>
```

This approach requires quite a lot of data transformation.

### 2. `*.csv.erb` template with `Ruby::CSV` (more correct approach)

Instead of transforming data in the above template, we can let `Ruby::CSV` handle the generation of correctly formatted CSV lines.

```ruby
# app/views/users/index.hmtl.erb
<%= link_to 'Export Users', users_path(format: :csv) %>
```

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  require 'csv'

  def index
    @users = User.all
    respond_to do |format|
      format.html
      format.csv do
        filename = ['Users', Date.today].join(' ')
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
        render template: 'users/index'
      end
    end
  end
```

```ruby
# app/views/users/index.csv.erb
<%- headers = ['Last Name', 'Email'] -%>
<%= CSV.generate_line headers %>
<%- @users.each do |user| -%>
  <%= CSV.generate_line([user.last_name, user.email]) -%>
<%- end -%>
```

This approach is more pure/less hacky.

### 3. Without a template (more generic approach)

Use
[`send_file` method](https://api.rubyonrails.org/v6.1.4/classes/ActionController/DataStreaming.html]
to assign user attributes that should be present in the generated CSV:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  require 'csv'

  def index
    @users = User.all
    respond_to do |format|
      format.html
      format.csv do
        filename = ['Users', Date.today].join(' ')
        send_data User.to_csv(@users), filename:, content_type: 'text/csv'
      end
    end
  end
```

Add `to_csv` method to the model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def self.to_csv(collection)
    CSV.generate(col_sep: ';') do |csv|
      csv << column_names
      collection.find_each do |record|
        csv << record.attributes.values
      end
    end
  end
end
```

I think this is a great approach to export all records and their attributes without messing with templates.

### 4. Concern: (most generic approach)

To make the #3 approach more scalable, we can extract the `to_csv` into a model convern that can be shared across different models:

```ruby
module GenerateCsv
  extend ActiveSupport::Concern
  require 'csv'

  class_methods do
    def to_csv(collection)
      CSV.generate(col_sep: ';') do |csv|
        # csv << attribute_names
        csv << column_names

        collection.find_each do |record|
          csv << record.attributes.values
        end
      end
    end
  end
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include GenerateCsv
end
```

That's it!
