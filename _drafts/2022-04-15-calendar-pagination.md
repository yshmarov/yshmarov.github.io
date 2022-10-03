---
layout: post
title: "Calendar Pagination with gem Pagy"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails pagination calendar
thumbnail: /assets/thumbnails/pagination.png
---

```ruby
# config/seeds.rb
50.times do
  Event.create(artist: Faker::Artist.name, start: Faker::Time.between(from: 10.days.ago, to: 10.days.from_now))
end
```

```ruby
bundle add pagy
touch config/initializers/pagy.rb
bundle add faker
rails g scaffold event start:datetime artist
rails db:migrate db:seed
```
https://ddnexus.github.io/pagy/api/calendar#gsc.tab=0
https://ddnexus.github.io/pagy/extras/calendar.html#gsc.tab=0

```ruby
# config/initializers/pagy.rb
# https://github.com/ddnexus/pagy/blob/master/lib/config/pagy.rb#L43
# https://ddnexus.github.io/pagy/extras/calendar#pagy_calendar_filtercollection-from-to

require 'pagy/extras/calendar'
# Pagy::Calendar::Week::DEFAULT[:offset] = 1 # Day offset from Sunday (0: Sunday; 1: Monday;... 6: Saturday)

# Date.beginning_of_week = :sunday # monday is default
```

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def index
    # @events = Event.order(start: :desc)
    # @pagy, @events = pagy(Event.order(created_at: :desc), items: 5)
    collection = Event.order(start: :asc)
    @calendar, @pagy, @events = pagy_calendar(collection, year: { size: [1, 1, 1, 1] },
                                                            month: { size: [0, 12, 12, 0],
                                                            # week: {},
                                                            format: '%b' },
                                                            day: { size: [0, 31, 31, 0], format: '%d' },
                                                            pagy: { items: 2 },
                                                            active: !params[:skip])
  end

  private

  def pagy_calendar_period(collection)
    # return [DateTime.now.getlocal, DateTime.now.getlocal]
    # return [DateTime.now.getlocal, DateTime.now.getlocal] if collection.empty?
    collection.map(&:start).minmax.map(&:getlocal)
  end

  def pagy_calendar_filter(collection, from, to)
    collection.where(start: from...to)
    # collection.where('start BETWEEN ? AND ?', from.utc, to.utc)
  end
end
```

```ruby
# app/views/events/index.html.erb
<% if @calendar %>
  <%== pagy_info(@pagy) %>
  <%== @calendar[:day].label %>
  <%== @calendar[:month].label(format: '%B %Y') %>

  <%== pagy_nav(@calendar[:year]) %>
  <%== pagy_nav(@calendar[:month]) %>
  <%== pagy_nav(@calendar[:day]) %>
<% end %>
<%== pagy_nav(@pagy) %>

<div id="events">
  <% @events.each do |event| %>
    <%= render event %>
  <% end %>
</div>

<% if params[:skip] %>
  <a href="?" >Show Calendar</a>
<% else %>
  <a href="?skip=true" >Hide Calendar</a>
<% end %>
```

[Good code](https://github.com/TomStary/receipt-calendar/commit/8c64141315bbe07e87d98eca3ce9cd502d1575d3)