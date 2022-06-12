---
layout: post
title: "Stop writing strftime"
author: Yaroslav Shmarov
tags: ruby-on-rails strftime
thumbnail: /assets/thumbnails/clock.png
---

[`strftime`](https://apidock.com/ruby/DateTime/strftime) is used to format `date` and `time` in Rails views.

The common (bad) approach would be to format a `datetime` with `strftime` directly in the views:

```ruby
post.created_at.strftime("%d %b, %Y")
# => 11 June, 2022
```

However, this way you store datetime formatting logic in views and there's a high chance of avoidable duplication.

What if we store `strftime` in the model?

```ruby
# app/models/post.rb

def created_at_dmy
  date.strftime("%d %b, %Y") # 11 June, 2022
end

post.created_at_dmy
# => 11 June, 2022
```

That's better, but there is a high chance that you will want to use the same `strftime` for other models in the app, and this method won't be accessible for them.

So you can just create a helper so that your `strftime` is available everywhere:

```ruby
# app/helpers/time_helper.rb

module TimeHelper
  def created_at_dmy(date)
    date.strftime("%d %b, %Y") # 11 June, 2022
  end
end

created_at_dmy(post.created_at)
# => 11 June, 2022
```

That's quite good. But there's an even better way offered by Rails!

The Rails API has inbuilt
[`Date::DATE_FORMATS`](https://edgeapi.rubyonrails.org/classes/Date.html)
and
[`Time::DATE_FORMATS`](https://api.rubyonrails.org/classes/Time.html)
classes, that we can use out of the box:

```ruby
post.created_at.to_s(:iso8601)
# => "2022-06-04T08:57:37Z"

post.created_at.to_s(:rfc822)
# => "Sat, 04 Jun 2022 08:57:37 +0000"

post.created_at.to_s(:short)
# => "04 Jun 08:57"

post.created_at.to_s(:long)
# => "June 04, 2022 08:57"
```

This way you can create an initializer to add your own methods:

```ruby
# config/initializers/date_format.rb

Time::DATE_FORMATS[:dmy] = "%d %b, %Y" # 04 June, 2022
Time::DATE_FORMATS[:my] = "%m/%Y" # 06/2022

post.created_at.to_s(:dmy)
# => 11 June, 2022

post.created_at.to_s(:my)
# => 06/2022
```

Ok, but what's the difference between `Date::DATE_FORMATS` and `Time::DATE_FORMATS`?

Well, the two classes can seem similar but they have a few different methods and can provide different outcomes:

```ruby
Date::DATE_FORMATS[:date1] = ->(date) { date.strftime("#{date.day.ordinalize} %B, %Y") }
post.created_at.to_s(:date1)
# => "2022-06-04 08:57:37 UTC"

Time::DATE_FORMATS[:time1] = ->(date) { date.strftime("#{date.day.ordinalize} %B, %Y") }
post.created_at.to_s(:time1)
# => "11th June, 2022"
```

Fantastic!

Additionally, as [Jerome](https://disqus.com/by/disqus_ALu6tEXrCI/) suggested, another **good** way to display `strftime` would be via `locales`:
* [official strftime locales guide](https://edgeguides.rubyonrails.org/i18n.html#adding-date-time-formats){:target="blank"}
* [locales source code](https://github.com/rails/rails/blob/b2eb1d1c55a59fee1e6c4cba7030d8ceb524267c/activesupport/lib/active_support/locale/en.yml#L3){:target="blank"}

That's it!