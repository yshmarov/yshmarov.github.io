---
layout: post
title: DateRangePicker with StimulusJS, Importmaps, gem Ransack
author: Yaroslav Shmarov
tags: ruby-on-rails stimulusjs daterangepicker
thumbnail: /assets/thumbnails/clock.png
---

Recently I've integrated "search between dates" into a Ruby on Rails application:

![daterangepicker-advanced-works](/assets/images/daterangepicker-advanced-works.gif)

[Daterangepicker](https://github.com/dangrossman/daterangepicker) is an ultra popular library. Unfortunately, it depends on jQuery. Luckily, there is a re-write that uses vanilla JS: [vanilla-datetimerange-picker](https://github.com/alumuko/vanilla-datetimerange-picker).

### 1. Display Daterangepicker with StimulusJS

```shell
rails g stimulus daterangepicker
```

```js
// app/javascript/controllers/daterangepicker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    new DateRangePicker(this.element, {})
  }
}
```

```html
<link type="text/css" rel="stylesheet" href="https://cdn.jsdelivr.net/gh/alumuko/vanilla-datetimerange-picker@latest/dist/vanilla-datetimerange-picker.css">
<script src="https://cdn.jsdelivr.net/momentjs/latest/moment.min.js" type="text/javascript"></script>
<script src="https://cdn.jsdelivr.net/gh/alumuko/vanilla-datetimerange-picker@latest/dist/vanilla-datetimerange-picker.js"></script>

<input type="text" data-controller="daterangepicker" size="24" style="text-align:center">
```

### 2. Improve assets import

Importing cdn in a rails file is a bad practice.

We can move the `<link>` tag into `application.css`:

```css
/* app/assets/stylesheets/application.css */
@import url('https://cdn.jsdelivr.net/gh/alumuko/vanilla-datetimerange-picker@latest/dist/vanilla-datetimerange-picker.css');
```

And import `moment` with importmaps:

```shell
./bin/importmap pin moment
```

```js
// app/javascript/application.js
import moment from 'moment'
window.moment = moment
```

So now you can remove 2 of the 3 CDN links:

```diff
-<link type="text/css" rel="stylesheet" href="https://cdn.jsdelivr.net/gh/alumuko/vanilla-datetimerange-picker@latest/dist/vanilla-datetimerange-picker.css">
-<script src="https://cdn.jsdelivr.net/momentjs/latest/moment.min.js" type="text/javascript"></script>
<script src="https://cdn.jsdelivr.net/gh/alumuko/vanilla-datetimerange-picker@latest/dist/vanilla-datetimerange-picker.js"></script>
```

[vanilla-daterange-picker](https://github.com/alumuko/vanilla-datetimerange-picker) does not exist as an npm package, so there is no straightforward way to import it. 

I tried to copy the code of the DateRangePicker into `app/assets/javascripts/libraries/vanilla-daterange-picker@3-1.js` and import it in application.js:

```js
// app/javascript/application.js
import { DateRangePicker } from 'vanilla-daterange-picker@3-1'
window.DateRangePicker = DateRangePicker
```

### 3. Submit and search between dates

```ruby
<%= form_with url: events_path, method: :get do |form| %>
  <%= form.text_field :start_date_between, value: params[:start_date_between], data: {controller: "daterangepicker"} %>
  <%= form.submit %>
<% end %>
```

This will submit data in the format `params[:start_date_between] = "05/01/2023 - 06/30/2023"`

We will search `Event` model by `start_date:datetime`:

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def index
    # params[:start_date_between] = "05/01/2023 - 06/30/2023"
    if params[:start_date_between].present?
      between_data_range = params[:start_date_between].split(' - ').map { |date| Date.strptime(date, '%m/%d/%Y') }
      @events = Event.where(start_date: between_data_range[0]..between_data_range[1]).order(start_date: :desc)
    else
      @events = Event.all.order(start_date: :desc)
    end
  end
end
```

Other ways to parse the date and search date range:

```ruby
starts = params[:start_date_between].split(" - ").first.to_date
ends = params[:start_date_between].split(" - ").last.to_date
@events = Event.where(start_date: starts..ends).order(start_date: :desc)

starts = params[:start_date_between].split(" - ").first
ends = params[:start_date_between].split(" - ").last
@events = Event.where("start_date >= ? AND start_date <= ?", starts, ends).order(start_date: :desc)
```

Result:

![daterangepicker-basic-works](/assets/images/daterangepicker-basic-works.gif)

### 4. Submit and search with Ransack

```sh
bundle add ransack
```

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def index
    @q = Event.all.ransack(params[:q])
    @events = @q.result(distinct: true)
  end
end
```

```ruby
# app/models/event.rb
class Event < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    ["start_date"]
  end
end
```

Enable a new `_between` ransacker that accepts data in the format `06 Feb 2022 - 25 Apr 2023` and searches a datetime attribute between these dates. So, `start_date_between` will accept the above data format.

```ruby
# config/initializers/ransack.rb
Ransack.configure do |config|
  config.add_predicate "between",
    arel_predicate: "between",
    formatter: proc { |v| Range.new(*v.split(" - ").map { |s| DateTime.parse(s) }) },
    validator: proc { |v| v.present? },
    type: :string
end
```

Display the form with search:

```ruby
<%= form_with url: events_path, method: :get do |form| %>
  <%= form.text_field :start_date_between, value: params.dig(:q, :start_date_between), data: {controller: "daterangepicker"} %>
  <%= form.submit %>
<% end %>
```

Now everything should work!

### 5. Configure and extend the DateRangePicker

Here are some great configs that you can use to make your daterangepicker look like this:

![daterangepicker-with-options](/assets/images/daterangepicker-with-options.png)

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="daterangepicker"
export default class extends Controller {
  initialize() {
    const ranges = {
      Today: [moment(), moment()],
      Yesterday: [moment().subtract('days', 1), moment().subtract('days', 1)],
      'Last 7 Days': [moment().subtract('days', 6), moment()],
      'Last 30 Days': [moment().subtract('days', 29), moment()],
      'This Month': [moment().startOf('month'), moment().endOf('month')],
      'Last Month': [moment().subtract('month', 1).startOf('month'), moment().subtract('month', 1).endOf('month')],
      'Last 365 Days': [moment().subtract('days', 364), moment()],
    }

    this.dateRangePicker = new DateRangePicker(this.element, {
      alwaysShowCalendars: true,
      ranges: ranges,
      opens: 'left',
      autoApply: true,
      showWeekNumbers: true,
      // locale: { format: 'MMM DD, YYYY' }, // Apr 27, 2023 - Apr 27, 2023
    })
  }
}
```

That's it!
