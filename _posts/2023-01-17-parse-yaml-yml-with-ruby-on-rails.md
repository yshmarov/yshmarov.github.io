---
layout: post
title: "Parse YAML with Ruby on Rails"
author: Yaroslav Shmarov
tags: ruby rails yaml yml
thumbnail: /assets/thumbnails/yaml.png
---

Instead of storing **static data** a database, you can create a structured YML or JSON file and parse it from your Ruby/Rails app.

I really like the data structure of a `.yml` file, because the syntax is much cleaner than `.json`.

Here's an example list of SupeRails episodes in the YAML format:

```yml
# db/view_data/superails-episodes.yml
- rank_number: 103
  title: "Ruby on Rails #103 Simple Omniauth without Devise"
  description: |
    Previously I’ve covered "Github omniauth with Devise".
    An even simpler solution would be to sign in via a social login provider (Github) without Devise at all! 
    Here’s the easiest way to create your whole social authentication solution from zero!
  tags:
    - omniauth
    - authentication

- rank_number: 102
  title: "Ruby on Rails #102 Email Calendar Invite"
  description: |
    In THIS episode we will EMAIL calendar invites and automatically add them to a users calendar!
    We will also handle updating/cancelling events!
  tags:
    - icalendar
    - email
    - action-mailer

- rank_number: 101
  title: "Ruby on Rails #101 iCalendar and .ics format. Add events to calendar"
  description: |
    Learn to create valid calendar events, that a user can download as an .ics file and add to his calendar!
  tags:
    - icalendar
```

You can parse this data (convert it into a Hash or Array) using Ruby on Rails **native yaml parsers**!

### 1. Parse a local YAML file with pure **Ruby**:

```ruby
require 'yaml'
path = "/Users/yaroslavshmarov/Downloads/superails-episodes.yml"
@episodes = YAML::load File.open(path)

@episodes.first.fetch('title')
# => "Ruby on Rails #103 Simple Omniauth without Devise"

# write to the yaml file
@episodes.first['title'] = 'New title'
File.write(path, @episodes.to_yaml)
```

Source: [Ruby YAML docs](https://ruby-doc.org/stdlib-2.5.1/libdoc/yaml/rdoc/YAML.html){:target="blank"}

### 2. Parse a YAML file inside a **Rails** app:

```ruby
# a controller action
  # @episodes = YAML::load File.open("#{Rails.root.to_s}/db/fixtures/superails-episodes.yml") # ruby way
  @episodes = YAML.load_file('db/fixtures/superails-episodes.yml') # rails way
  @episodes.inspect
```

Render the results in a view:

```ruby
# a view
<% @episodes.each do |episode| %>
  <%= episode.fetch('name') %>
  <%= episode['title'] %>
<% end %>
```

### 3. Parse a yml file from URL, fix `Psych::DisallowedClass`

```ruby
require 'open-uri'
path = "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/master/_data/conferences.yml"
uri = URI.open(path)
yaml = YAML.load_file uri, permitted_classes: [Date]
# yaml = YAML.load File.read(uri), permitted_classes: [Date]
```

Source: [Rails YAML.load_file docs](https://apidock.com/ruby/YAML/load_file/class){:target="blank"}

That's it! 🤠
