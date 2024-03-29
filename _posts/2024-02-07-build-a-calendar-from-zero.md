---
layout: post
title: Build a calendar from zero (Month view)
author: Yaroslav Shmarov
tags: ruby-on-rails calendar
thumbnail: /assets/thumbnails/calendar.png
youtube_id: 08UCWWGKl8k
---

A long time ago I thought it impossible to build a calendar on your own; I thought you need an external library. However building a calendar is much easier than you think!

Usual requirements:
- link to `Today`, `prev`, `next`
- update URL based on current page
- `Month`/`Week`/`Day` view
- display records
- display current day/time

Let's build this month view:

![Monthly Calendar](/assets/images/calendar-month-demo.gif)

First, create a route:

```ruby
  get "calendar/month", to: "calendar#month"
#  get "calendar/week", to: "calendar#week"
#  get "calendar/day", to: "calendar#day"
```

If you add a `date` param in the URL like [`http://localhost:3000/calendar/month?date=2023-08-01`](http://localhost:3000/calendar/month?date=2023-08-01), it will open the month that contains this date

```ruby
# app/controllers/calendar_controller.rb
class CalendarController < ApplicationController
  def month
    @date = Date.parse(params.fetch(:date, Date.today.to_s))
    @events = Event.where(start_date: @date.all_month)
  end

  # def week
  # end

  # def day
  # end
end
```

View helpers for the month view:

```ruby
# app/helpers/calendar_helper.rb
module CalendarHelper
  # if month starts on Monday => 0
  # if month starts on Wed => 2
  def month_offset(date)
    # you might want to update this based on your first day of the week (Sun/Mon)
    date.beginning_of_month.wday - 1
  end

  def today?(day)
    day == Date.today
  end

  def today_class(day)
    "bg-rose-200" if today?(day)
  end
end
```

Finally, display the calendar and events per day:

```ruby
# app/views/calendar/month.html.erb
<%= tag.div class: "flex justify-between" do %>
  <%= @date.strftime('%B %Y') %>
  <%= tag.div class: "flex space-x-4" do %>
    <%= link_to "<", calendar_month_path(date: @date - 1.month) %>
    <%= link_to "Today", calendar_month_path %>
    <%= link_to ">", calendar_month_path(date: @date + 1.month) %>
  <% end %>
<% end %>

<%= tag.div class: "grid grid-cols-7" do %>
  <% Date::ABBR_DAYNAMES.rotate.each do |day| %>
    <%= tag.div class: "border" do %>
      <%= day %>
    <% end %>
  <% end %>
  <% month_offset(@date).times do %>
    <%= tag.div %>
  <% end %>
  <% @date.all_month.each do |day| %>
    <%= tag.div class: "border min-h-24 #{today_class(day)}" do %>
      <%= day.strftime('%d') %>
      <% @events.where(start_date: day.all_day).each do |event| %>
        <%= render 'events/event', event: event %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

```ruby
ℹ️
Date::ABBR_DAYNAMES
=> ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
irb(main):002> Date::ABBR_DAYNAMES.rotate
=> ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
Date::ABBR_DAYNAMES.rotate(3)
=> ["Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue"]
```

### Abstraction: 

We can wrap the calendar into a similar helper like [excid3/simple_calendar](https://github.com/excid3/simple_calendar) does:

```ruby
<%= month_calendar do |date| %>
  <%= date %>
<% end %>
```

First, abstract the month calendar wrapper: 

```ruby
# app/views/calendar/_month.html.erb
<%= tag.div class: "flex justify-between" do %>
  <%= date.strftime('%B %Y') %>
  <%= tag.div class: "flex space-x-4" do %>
    <%= link_to "<", calendar_month_path(date: date - 1.month) %>
    <%= link_to "Today", calendar_month_path %>
    <%= link_to ">", calendar_month_path(date: date + 1.month) %>
  <% end %>
<% end %>

<%= tag.div class: "grid grid-cols-7" do %>
  <% Date::ABBR_DAYNAMES.rotate.each do |day| %>
    <%= tag.div class: "border" do %>
      <%= day %>
    <% end %>
  <% end %>
  <% month_offset(date).times do %>
    <%= tag.div %>
  <% end %>
  <% date.all_month.each do |day| %>
    <%= tag.div class: "border min-h-24 #{today_class(day)}" do %>
      <%= yield day %>
    <% end %>
  <% end %>
<% end %>
```

Next, render the `day` (the thing you want to have whole control of) inside the wrapper:

```ruby
# app/views/calendar/month.html.erb
<%= render 'calendar/month', date: @date do |day| %>
  <%= day.strftime('%d') %>
  <% @events.where(start_date: day.all_day).each do |event| %>
    <%= render 'events/event', event: event %>
  <% end %>
<% end %>
```

### Improve query performance

With the above approach, we perform an additional query for each day in the calendar:

![too-many-queries](/assets/images/calendar-too-many-queries.png)

Instead, we can **group events by day** in the controller, and display events per day in the view:

```diff
# app/controllers/calendar_controller.rb
class CalendarController < ApplicationController
  def month
    @date = Date.parse(params.fetch(:date, Date.today.to_s))
-    @events = Event.where(start_date: @date.all_month)
+    @events = Event.where(start_date: @date.all_month).group_by{ |e| e.start_date.to_date }
  end
end
```

```diff
# app/views/calendar/month.html.erb
<%= render 'calendar/month', date: @date do |day| %>
  <%= day.strftime('%d') %>
-  <% @events.where(start_date: day.all_day).each do |event| %>
+  <% @events[day]&.each do |event| %>
    <%= render 'events/event', event: event %>
  <% end %>
<% end %>
```

1 query in the controller + 31 queries in the view => 1 query in the controller!

### Next steps:

1. Day, Week views
2. Hotwire scroll up/down to prev/next period
3. Select First day of week
4. i18n
5. Dedicatet stylesheet to style the calendar in isolation
6. Drag & drop events between days
