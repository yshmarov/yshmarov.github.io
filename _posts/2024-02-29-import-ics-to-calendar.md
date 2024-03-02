---
layout: post
title: "Import ICS events to calendar"
author: Yaroslav Shmarov
tags: rails icalendar ics
thumbnail: /assets/thumbnails/calendar.png
---

Previously I wrote the [Complete guide to iCalendar events with Ruby]({% post_url 2023-01-03-icalendar-ruby %}) that focused on **creating** events that can be **exported** to a calendar in the `.ics` format.


Recently [Hey Calendar](https://www.hey.com/calendar/) [added a feature](https://twitter.com/heyhey/status/1762657536379855013) to import events to their calendar.

![icalendar-hey-import-ics](/assets/images/icalendar-hey-import-ics.png)

This got me intrigued on how I can parse an `.ics` file and import it into my app.

Obviously, it can be done with the same [`gem icalendar`](https://github.com/icalendar/icalendar), specifically with the [`.parse`](https://github.com/sdague/icalendar/blob/master/lib/icalendar/parser.rb#L16) method.

### Create a parser

First, install icalendar gem:

`bundle add icalendar`

Next, create a method to receive a `.ics` file, parse it and create an event:

```ruby
# app/models/event.rb

# require 'icalendar'
class Event < ApplicationRecord

  def self.create_from_ics(file)
    cal_file = File.open(file)
    cal = Icalendar::Calendar.parse(cal_file).first
    cal_event = cal.events.first
    Event.create(
      name: cal_event.summary.strip,
      description: cal_event.description.strip,
      starts_at: cal_event.dtstart,
      ends_at: cal_event.dtend,
      location: cal_event.location.strip
    )
  end
end
```

Here's a [dummy .ics event](/Sunday+morning+yoga+in+Antibes+.ics) you can play with!

### Create a form

route

```diff
# config/routes.rb
Rails.application.routes.draw do
  resources :events
+  post "events/import" => "events#import"
end
```

view

```ruby
# app/views/events/index.html.erb
<%= form_with url: events_import_path, method: :post do |form| %>
  <%#= form.file_field :file %>
  <%= form.file_field :files, multiple: true %>
  <%= form.submit "Import" %>
<% end %>
```

controller

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def import
    files = params[:files]
    files = files.reject(&:blank?)

    files.each do |file|
      Event.create_from_ics(file)
    end

    redirect_to events_url, notice: "Importing event from ICS file"
  end
end
```

Voila! Now we can upload multiple `.ics` files and create events from them:

![import ics events](/assets/images/import-ics-events.gif)

### Using ActiveJob

Create a job `rails g job IcsImport`

```ruby
# app/jobs/ics_import_job.rb

# gem icalendar
require 'icalendar'

class IcsImportJob < ApplicationJob
  queue_as :default

  def perform(file_path:)
    # file_path = 'test/fixtures/files/Sunday+morning+yoga+in+Antibes+.ics'
    # cal_file = File.open(file_path)

    cal_file = File.open(file_path)
    cal = Icalendar::Calendar.parse(cal_file).first
    cal_event = cal.events.first

    event_object = OpenStruct.new(
      name: cal_event.summary.strip,
      description: cal_event.description.strip,
      starts_at: cal_event.dtstart,
      ends_at: cal_event.dtend,
      location: cal_event.location.strip
    )
    Event.create(event_object.to_h)
  end
end
```

🚨 It's tricker with the controller!

If you just call `IcsImportJob.perform_later(params[:file])`, you will get an error `ActionDispatch::Http::UploadedFile`.

Copilot to the rescue:

![ActionDispatch::Http::UploadedFile](/assets/images/ActionDispatch-HTTP-UploadedFile.png)

update the events controller accordingly:

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def import
    files = params[:files]
    files = files.reject(&:blank?)

    # files.each do |file|
    #   Event.create_from_ics(file)
    # end

    files.each do |file|
      tempfile = Tempfile.new
      tempfile.binmode
      tempfile.write(file.read)
      tempfile.close
      IcsImportJob.perform_later(file_path: tempfile.path)
    end

    redirect_to events_url, notice: "Importing event from ICS file"
  end
end
```

Again, here's a [dummy .ics event](/Sunday+morning+yoga+in+Antibes+.ics) you can play with. I suggest storing it in `test/fixtures/files/*`.

Write some tests

```ruby
# test/jobs/ics_import_job_test.rb
require "test_helper"

class IcsImportJobTest < ActiveJob::TestCase
  test "imports an event from an ICS file" do
    file_path = "test/fixtures/files/Sunday+morning+yoga+in+Antibes+.ics"
    IcsImportJob.perform_now(file_path:)
    event = Event.last
    assert_equal "Sunday morning yoga in Antibes", event.name
    assert_equal "Plage de la Gravette, Antibes (Small beach behind Port Vauban, Antibes, France)", event.location
    assert_equal "2024-03-03 10:30:00 +0100", event.starts_at
    assert_equal "2024-03-03 11:30:00 +0100", event.ends_at
  end
end
```

That's it! Good luck building your calendar app!
