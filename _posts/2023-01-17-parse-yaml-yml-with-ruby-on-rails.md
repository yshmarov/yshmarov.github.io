---
layout: post
title: "Parse a YML/YAML file in a Ruby on Rails app"
author: Yaroslav Shmarov
tags: ruby rails yaml yml json
thumbnail: /assets/thumbnails/yaml.png
---

Instead of storing **static data** a database, you can create a structured YML or JSON file and parse it from your Ruby/Rails app.

I really like the data structure of a `.yml` file, because it is much cleaner to write than `.json`.

Here's an example list of schools in the YAML format:

```yml
# db/view_data/schools.yml
- name: Austin High School
  team_name: Austin Mustangs
  city: Houston
  state: TX
  primary_color: green
  secondary_color: white

- name: Bellaire High School
  team_name: Bellaire Cardinals
  city: Houston
  state: TX
  primary_color: red-lighter
  secondary_color: white

- name: Carnegie Vanguard High School
  team_name: Carnegie Vanguard Rhinos
  city: Houston
  state: TX
  primary_color: blue
  secondary_color: red-lighter
```

You can parse this data (convert it into a Hash or Array) using Ruby on Rails **native yaml parsers**!

1. Parse a local YAML file with pure **Ruby**:

```ruby
require 'yaml'
path = "/Users/yaroslavshmarov/Documents/GitHub.nosync/schools.yml"
@schools = YAML::load File.open(path)

@schools.first.fetch('name')
# => "Austin High School"
```

Source: [Ruby YAML docs](https://ruby-doc.org/stdlib-2.5.1/libdoc/yaml/rdoc/YAML.html){:target="blank"}

2. Parse a YAML file inside a **Rails** app:

```ruby
# a controller action
  # @schools = YAML::load File.open("#{Rails.root.to_s}/db/fixtures/schools.yml") # ruby way
  @schools = YAML.load_file('db/fixtures/schools.yml') # rails way
  @schools.inspect
```

Render the results in a view:

```ruby
# a view
<% @schools.each do |school| %>
  <%= school.fetch('name') %>
  <%= school['name'] %>
<% end %>
```

Source: [Rails YAML.load_file docs](https://apidock.com/ruby/YAML/load_file/class){:target="blank"}

That's it! 🤠
