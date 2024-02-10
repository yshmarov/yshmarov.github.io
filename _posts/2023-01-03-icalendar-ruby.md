---
layout: post
title: "Complete guide to iCalendar events with Ruby"
author: Yaroslav Shmarov
tags: ical icalendar ruby-on-rails
thumbnail: /assets/thumbnails/calendar.png
youtube_id: CVt5LQfi8Dk
---

It's common to receive a calendar invita via email:

![calendar-invite.png](/assets/images/calendar-invite.png)

In reality, the email just has a file with `.ics` extension attached. You email client recognizes it and adds it to your calendar.

An `.ics` file can look more-less like this:

![ics-example.png](/assets/images/ics-example.png)

You can use [gem icalendar](https://github.com/icalendar/icalendar){:target="blank"} to generate `.ics` files with Ruby.

### Initial setup

Let's assume that a **User** wants to add a sports **Game** to his calendar.

Let's generate some dummy events:

```ruby
# config/seeds.rb
5.times do |index|
  starts_at = index.days.ago
  ends_at = starts_at + 2 * 60 * 60
  title = Faker::Sports.sport
  description = Faker::Quote.famous_last_words
  address = Faker::Address.full_address
  game = Game.create!(starts_at:, ends_at:, title:, description:, address:)
end

5.times do |index|
  starts_at = index.days.ago
  ends_at = starts_at + 2 * 60 * 60
  title = Faker::Sports.sport
  description = Faker::Quote.famous_last_words
  address = Faker::Address.full_address
  game = Game.create!(starts_at:, ends_at:, title:, description:, address:)
end
```

```shell
bundle add faker
rails g scaffold Game starts_at:datetime ends_at:datetime title:string description:text address:text
rails db:migrate db:seed
```

### Create a rich `.ics` file

We will generate `.ics` files for game/user in a **Service**, so that it is reusable:

```shell
bundle add icalendar

mkdir app/services
mkdir app/services/games
echo > app/services/games/icalendar_event.rb
```

The icalendar object with almost all possible options:

```ruby
# app/services/games/icalendar_event.rb
# Games::IcalendarEvent.new(game: Game.last).call
# Games::IcalendarEvent.new(game: Game.last, user: User.last).call
class Games::IcalendarEvent
  require 'icalendar'
  include Rails.application.routes.url_helpers

  def initialize(game:, user: nil)
    @game = game
    @user = user
    @url = game_url(@game)
  end

  def call
    ical = ::Icalendar::Calendar.new
    event = ::Icalendar::Event.new
    event.dtstart = Icalendar::Values::DateTime.new @game.starts_at
    event.dtend = Icalendar::Values::DateTime.new @game.ends_at
    event.summary = @game.title
    event.description = "Watch #{@game.title} live at #{@url}"
    event.uid = @game.id.to_s # important for updating/canceling an event
    event.sequence = Time.now.to_i # important for updating/canceling an event
    event.url = @url
    event.location = @game.address # location on map
    # event.attendee = %w(mailto:abc@example.com mailto:xyz@example.com)
    if @user.present?
      event.attendee = Icalendar::Values::CalAddress.new("mailto:#{@user.email}", partstat: 'accepted') # DECLINED # TENTATIVE
    end
    # event.organizer = "mailto:organizer@example.com"
    event.organizer = Icalendar::Values::CalAddress.new("mailto:#{ApplicationMailer.default_params[:from]}", cn: 'Yaro from Superails')
    event.status = 'CONFIRMED' # 'CANCELLED'
    event.ip_class = 'PUBLIC' # 'PRIVATE'
    # event.attach = Icalendar::Values::Uri.new @url
    # event.append_attach = Icalendar::Values::Uri.new(@url, "fmttype" => "application/binary")
    event.created = @game.created_at
    event.last_modified = @game.updated_at

    event.alarm do |a|
      a.summary = "#{@game.title} starts in 30 minutes!"
      a.trigger = '-PT30M'
    end

    ical.add_event(event)
    ical.append_custom_property('METHOD', 'REQUEST') # add event to calendar by default!
    ical.publish
    # ical.ip_method = 'REQUEST'
    # ical.ip_method = 'PUBLISH'
    # ical.ip_method = 'CANCEL'
    ical
  end
end
```

The [complete icalendar documentation](https://www.rfc-editor.org/rfc/rfc5545){:target="blank"} can give you more insight on all the above options.

This way you can call 

```ruby
Games::IcalendarEvent.new(game: Game.last).call
```

or

```ruby
Games::IcalendarEvent.new(game: Game.last, user: User.last).call
```

and generate an ical object for any game-user pair.

**How can we deliver the `.ics` file?**

That there are 3 common ways to share calendar events with users:
1. Link to download ical file **(easiest)**
2. webcal: allow user to "sync with a remote calendar"
3. Send calendar invite via email **(most common)**

### 1. Link to download icalendar file

This way a user can download a game/event as an `.ics` file, click on it and add it to his calendar:

```ruby
# app/controllers/games_controller.rb
def show
  respond_to do |format|
    format.html
    format.ics do
      # calendar = Games::IcalendarEvent.new(game: @game, user: User.last).call
      calendar = Games::IcalendarEvent.new(game: @game).call
      send_data calendar.to_ical, type: 'text/calendar', disposition: 'attachment', filename: "Game#{@game.id}.ics"
      # render body: calendar.to_ical
      # render inline: calendar.to_ical
      # render plain: calendar.to_ical
    end
  end
end
```

```ruby
<%= link_to game.title, game_path(game, format: :ics) %>
```

Adding a downloaded `.ics` file to calendar:

![download-ics-add-to-calendar.png](/assets/images/download-ics-add-to-calendar.png)

### 2. [Webcal](https://en.wikipedia.org/wiki/Webcal) calendar sync

Allow a user to "subscribe" to your calendar. His calendar app will "ping" your calendar endpoint from time to time to get the updated events list.

In the below example, we add **all** games/events to the calendar:

```ruby
# app/controllers/games_controller.rb
# class GamesController < ActionController::Base
class GamesController < ApplicationController
  skip_before_action :authenticate_user, only: :index

  def index
    @games = Game.all
    respond_to do |format|
      # format.html
      format.ics do
        cal = Icalendar::Calendar.new
        cal.x_wr_calname = 'All games'

        @games.each do |game|
          cal.event do |event|
            event.dtstart = game.starts_at
            event.dtend = game.ends_at
            event.summary = game.title
            event.description = game.description
            event.uid = game.id.to_s
            event.sequence = Time.now.to_i
          end
        end

        cal.publish
        render plain: cal.to_ical
      end
    end
  end
end
```

Add a link to "subscribe" to the calendar. When the user clicks the link, it will open in the users calendar app and suggest adding an external calendar:

```ruby
<%= link_to 'subscribe', games_url(protocol: :webcal, format: :ics) %>
```

When you click the link, it will open your calendar app and suggest adding/syncing a calendar:

![webcal-calendar-add.png](/assets/images/webcal-calendar-add.png)

In a few seconds, you will see all the calendar events in your calendar app:

![webcal-calendar-added.png](/assets/images/webcal-calendar-added.png)

Important notes:

- The URL should be publicly accessible
- Must use URL helpers, not path helpers
- `protocol` must be `webcal`, not `http`
- `format` must be `ics`
- `render plain` in controller
- `cal.x_wr_calname` to set default calendar name

**This will not work on localhost, because you don't have a real web url that the calendar app can send a request to!** => use nginx, or do it on staging/production.

### 3. Send calendar invite via email

We are all used to getting invites via email and accepting/declining them.

Let's create a button to email the event to the calendar:

```shell
rails g mailer game_mailer add_game
```

```ruby
# config/routes.rb
resources :games do 
  member do
    post :email_to_calendar
  end
end
```

```ruby
# app/controllers/streaming/game_streams_controller.rb
def email_to_calendar
  @game = Game.find(params[:id])
  # send email here
  GameMailer.with(game: @game, user: current_user).add_game.deliver_later
  redirect_to games_path, notice: 'Email sent'
end
```

```ruby
# app/mailers/game_mailer.rb
class GameMailer < ApplicationMailer
  def add_game
    @game = params[:game]
    @user = params[:user]
    @game_url = streaming_sport_game_stream_url(sport_slug: @game.sport_slug, game_slug: @game.slug)
    @subject = [@game.title, @game.display_starts_at].join(', ')
    ical = Games::IcalendarEvent.new(game: @game, user: @user).call # generate the ical file

    # attach ICS file
    mail.attachments["#{@subject}.ics"] = { mime_type: 'application/ics', content: ical.to_ical }
    # mail.attachments["#{@subject}.ics"] = { mime_type: 'text/calendar', content: ical.to_ical }
    # mail.attachments["#{@subject}.ics"] = { mime_type: 'text/calendar; method=REQUEST', content: ical.to_ical }

    mail to: @user.email,
         from: 'Yaro from Superails <admin@superails.com>',
         cc: Rails.application.config_for(:settings)[:support_email],
         subject: @subject
  end
end
```

```ruby
<%= button_to 'Email to calendar', email_to_calendar_game_path(game) %>
```

Now when you click the link, an email invite will be sent:

![calendar-invite.png](/assets/images/calendar-invite.png)

If you send follow-up emails with changed start/end time of the event, it will be automatically updated in the users calendar! Also, if you send an update with `event.status = 'CANCELLED'`, the event will be removed from the calendar!

That's it! 🎉🥳🍾

References:
* [gem add_to_calendar](https://github.com/jaredlt/add_to_calendar){:target="blank"}
* [Great post: adding/updating/cancelling events](https://joshfrankel.me/blog/lemme-pencil-you-in-using-icalendar-and-rails-to-sync-calendar-events/){:target="blank"}
* [recurring ical events](https://tech.studyplus.co.jp/entry/2021/05/27/100000){:target="blank"}
* [full-day events](https://notepad.onghu.com/2018/creating-icalendar-files-with-full-day-events-inruby/){:target="blank"}
* [webcal sync](https://toasterlovin.com/rails-webcal-links-with-icalendar-gem/){:target="blank"}
* [tldr: attach ical event to email](https://dev.to/codesalley/ruby-on-rails-event-invitation-add-to-calendar-using-icalendar-gem-42jf){:target="blank"}
