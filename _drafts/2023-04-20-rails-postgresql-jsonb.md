---
layout: post
title: "JSONB"
author: Yaroslav Shmarov
tags: rails postgresql json jsonb
thumbnail: /assets/thumbnails/json.png
---

`jsonb` (JSON Binary) is a Postgresql specific data type. It has higher performance than regular `json`.

```json
metadata = {
  "name": "John Smith",
  "email": "john@example.com",
  "phone": {
    "home": "555-1234",
    "work": "555-5678"
  }
}
```

Querying examples:

```ruby
user = User.find(1)
# find
users = User.where("metadata ->> 'country' = ?", 'USA')
users = User.where("metadata -> 'phone' ->> 'home' = ?", '555-1234')
# update
user.update(metadata: { "country": "Canada" })
user.update("metadata -> 'phone' ->> 'home'" => '555-4321')
# create
user = User.create(metadata: { "country": "USA", "phone": { "home": "555-1234" } })
```
