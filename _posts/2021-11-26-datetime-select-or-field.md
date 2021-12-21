---
layout: post
title: "TIL: date_select VS date_field"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails today-i-learned html
thumbnail: /assets/thumbnails/clock.png
---

There are different ways to display `time`, `date`, `date_time` fields in a rails app:

```ruby
<%= form.time_select :published_at %>
<%= form.time_field :published_at %>

<%= form.date_select :published_at %>
<%= form.date_field :published_at %>

<%= form.datetime_select :published_at %>
<%= form.datetime_field :published_at %>
```

Safari view:
![safari datetime select](/assets/images/safari-datetime.png)

Firefox view:
![firefox datetime select](/assets/images/firefox-datetime.png)

I like the `*_field` much more than `*_select` variants in this case.

[My inital tweet about this](https://twitter.com/yarotheslav/status/1452011312503009283){:target="blank"}
