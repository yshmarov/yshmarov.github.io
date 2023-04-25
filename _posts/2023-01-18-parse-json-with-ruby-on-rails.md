---
layout: post
title: "Parse JSON with Ruby on Rails"
author: Yaroslav Shmarov
tags: ruby rails json
thumbnail: /assets/thumbnails/json.png
---

JSON is possibly the most popular format for **sharing** data via API.

Sometimes you just have a JSON that you have to feed into your app.

First, here's an example json file:

```json
// db/view_data/superails-episodes.json
[
  {
    "rank_number": 103,
    "title": "Ruby on Rails #103 Simple Omniauth without Devise",
    "description": "Previously I’ve covered \"Github omniauth with Devise\".\nAn even simpler solution would be to sign in via a social login provider (Github) without Devise at all! \nHere’s the easiest way to create your whole social authentication solution from zero!\n",
    "tags": [
        "omniauth",
        "authentication"
    ]
  },
  {
    "rank_number": 102,
    "title": "Ruby on Rails #102 Email Calendar Invite",
    "description": "In THIS episode we will EMAIL calendar invites and automatically add them to a users calendar!\nWe will also handle updating/cancelling events!\n",
    "tags": [
        "icalendar",
        "email",
        "action-mailer"
    ]
  },
  {
    "rank_number": 101,
    "title": "Ruby on Rails #101 iCalendar and .ics format. Add events to calendar",
    "description": "Learn to create valid calendar events, that a user can download as an .ics file and add to his calendar!\n",
    "tags": [
        "icalendar"
    ]
  }
]
```

### 1. Parse JSON with Ruby:

```ruby
path = "/Users/yaroslavshmarov/Downloads/superails-episodes.json"
data = File.read(path)
require 'json'
json = JSON.parse(data)

json.first['rank_number']
# => 103
json.map { |element| element['title'] }
# =>
# ["Ruby on Rails #103 Simple Omniauth without Devise",
#  "Ruby on Rails #102 Email Calendar Invite",
#  "Ruby on Rails #101 iCalendar and .ics format. Add events to calendar"]

json.first['title'] = 'New title'
# write to the json file
File.write(path, JSON.dump(data))
```

### 2. Parse JSON within Rails:

```ruby
data = File.read('./db/fixtures/superails-episodes.json')
json = JSON.parse(data)
```

### 3. Parse JSON from a remote URL

```ruby
require 'open-uri'
path = "https://raw.githubusercontent.com/erik-sytnyk/movies-list/master/db.json"
uri = URI.open(path)
uri_json = JSON.load(uri)
```

That's it! 🤠
