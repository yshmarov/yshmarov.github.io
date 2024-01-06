---
layout: post
title: "Calendar pagination with Pagy"
author: Yaroslav Shmarov
tags: ruby rails calendar pagination
thumbnail: /assets/thumbnails/calendar.png
---

Peviously I wrote about [paginating records by date]({% post_url 2021-11-04-paginate-tab-by-any-attribute %}).

Gem pagy also [offers a pagination solution](https://ddnexus.github.io/pagy/docs/extras/calendar/) out of the box:

![calendar pagination](/assets/images/pagy-calendar.png)

Here's how we can (and can't) use it.

### Initial setup

First, let's add a list of events that we can paginate:

```ruby
# /db/seeds.rb
path = "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/master/_data/conferences.yml"
uri = URI.open(path)
yaml = YAML.load_file uri, permitted_classes: [Date]

yaml.each do |event|
  Event.create!(
    name: event["name"],
    location: event["location"],
    start_date: event["start_date"]
  )
end
```

```shell
rails g scaffold Event name location start_date:datetime
rails db:migarte db:seed
```

### Add calendar pagination

```shell
bundle add pagy
```

Enable pagy calendar plugin:

```ruby
# config/initializers/pagy.rb
require 'pagy/extras/calendar'

# optionally enable frontend libraries
# require 'pagy/extras/bootstrap' # https://ddnexus.github.io/pagy/docs/extras/bootstrap/
# https://ddnexus.github.io/pagy/docs/extras/tailwind/
```

Pagy does not know what `date` attribute we will use for pagination (`created_at`? `starts_at`? `start_time`?), so we have to define it:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # enable pagy backend helpers globally
  include Pagy::Backend

  # start and end of calendar (first and last record in the list)
  def pagy_calendar_period(collection)
    # collection.minmax.map(&:start_date)

    # between first event and Today
    start_date = collection.min_by(&:start_date).start_date
    end_date = Time.zone.now
    [start_date, end_date]
  end

  # query to paginate within start_date
  def pagy_calendar_filter(collection, from, to)
    collection.where(start_date: from..to)
  end
end
```

Enable pagy froentend helpers like `pagy_nav`:

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include Pagy::Frontend
end
```

In the controller, wrap your collection into `pagy_calendar`.
Uncomment for any pagination granularity that you like:
- year
- year/month
- year/week
- year/day (stupid)
- year/month/day
- ???

```ruby
  def index
    collection = Event.all.order(start_date: :asc)
    @calendar, @pagy, @events = pagy_calendar(collection,
      year:  { size:  [1, 1, 1, 1] },
      month:  { size: [0, 12, 12, 0], format: '%b' },
      # week:  { size: [0, 53, 53, 0], format: '%W' },
      day:  { size: [0, 31, 31, 0], format: '%d' },
      pagy:  { items: 10 }, # items per page
      active: !params[:skip]
    )
  end
```

ℹ️ `size` attribute defines how many pagy links to show: `[pagination start, before current, after current, pagination end]`. For example, if current selected page is `11` and `size: [1, 2, 2, 1]`, the pagination links displayed can be `[1, 9-10, 12-13, 100]`.

Display records (events) and pagination in a view:

```ruby
# app/views/events/index.html.erb
<h1>Events</h1>

<div>
  <% if params[:skip] %>
    <%= link_to 'Show Calendar', events_path %>
  <% else %>
    <%= link_to 'Hide Calendar', events_path(skip: true) %>
    <%= link_to 'Today', pagy_url_for(@calendar.send(:last_object_at, Time.zone.now), 1) %>
    <%#= link_to 'Today (does not work)', pagy_calendar_url_at(@calendar, Time.zone.now) %>
  <% end %>
</div>

<% if @calendar %>
  <%== pagy_info(@pagy) %>
  for
  <%#== @calendar[:year].label %>
  <%== @calendar[:day]&.label %>
  <%== @calendar[:month].label(format: '%B %Y') %>
  <%#== @calendar[:week].label %>
  <%== pagy_nav(@calendar[:year]) %>
  <%== pagy_nav(@calendar[:month]) %>
  <%== pagy_nav(@calendar[:week]) if @calendar[:week] %>
  <%== pagy_nav(@calendar[:day]) if @calendar[:day] %>
<% end %>

<%== pagy_nav(@pagy) %>

<hr>
<% if @events.any? %>
  <% @events.each do |event| %>
    <%= render 'event', event: event %>
  <% end %>
<% elsif @events.empty? %>
  No events found
<% end %>

```

### Open questions

1. `pagy_calendar_url_at` does not work for me: `undefined method pagy_calendar_url_at' for #<ActionView::Base:0x0000000000b7c0>`

1. If we could have actual **year** in params, not **page index**, it would make URLs predictable:
```ruby
# bad
http://localhost:3000/events?year_page=10&month_page=10&day_page=5
# good
http://localhost:3000/events?year_page=2023&month_page=10&day_page=5
```

1. It would be cool to define `format` in view `pagy_nav(@calendar[:day], format: "%d")`, not just in controller `day:  { size: [0, 31, 31, 0], format: '%d' }`.

1. Add new event to current date

When `format` is defined inside the controller, it can be hard to get current selected date in the view:
```ruby
# app/views/events/index.html.erb
# if no format defined in controller
<%= link_to "Add event", new_event_path(start_date: @calendar[:day].label) %>

# if :day format is defined in controller, we have to deduce todays date
<%= link_to "New event", new_event_path(start_date: [@calendar[:day]&.label, @calendar[:month].label(format: '%m-%Y')].compact.join('-')) %>

<%= link_to "Add event (Today)", new_event_path(start_date: Date.today) %>
```
Display the selected date in a form:
```ruby
# app/views/events/_form.html.erb
<%= form.datetime_field :start_date, value: params[:start_date].to_date.strftime('%Y-%m-%dT%H:%M:%S') || @object.start_date %>
```
Redirect to current page
```ruby
# app/controllers/events_controller.rb
# Does not work because @calendar is not defined. We would need to provide it's context.
def create
  if @event.save
    redirect_to events_path(pagy_calendar_url_at(@calendar, @event.start_date))
```

Overall, Pagy Calendar is a great out of the box solution. Huge respect to [ddnexus](https://github.com/ddnexus/) for his work! 💪

To explore later:
- Time zones
- i18n
