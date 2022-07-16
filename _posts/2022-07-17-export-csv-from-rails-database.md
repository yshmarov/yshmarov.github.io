---
layout: post
title: "Export CSV from Rails"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails export excel xls xlsx csv download
thumbnail: /assets/thumbnails/xlsx.png
---

In a
[previous article]({% post_url 2021-08-20-export-from-database-to-excel %}){:target="blank"}
we **exported** data from a Rails database to XLSX using a gem.

We can export to CSV without any external gems, because Ruby has an in-built CSV processor.

![export-csv-rails](/assets/images/export-csv-rails.gif)

I see two good approaches to generating CSV:

1. With a template

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
<%- headers = ['First Name', 'Email'] -%>
<%= CSV.generate_line headers %>
<%- @users.each do |user| -%>
  <%= CSV.generate_line([user.name, user.email]) -%>
<%- end -%>
```

2. Without a template

Create a method in the user model to generate a CSV for the provided fields:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def self.to_csv(fields)
    CSV.generate do |csv|
      csv << fields
      all.each do |user|
        csv << user.attributes.values_at(*fields)
      end
    end
  end
end
```

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
        send_data @users.to_csv(%w[name surname email phone])
      end
    end
  end
```

Personally I find the first option (with a template) easier.

That's it!
