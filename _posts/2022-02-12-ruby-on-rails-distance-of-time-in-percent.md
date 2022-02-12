---
layout: post
title: 'Tip: distance_of_time_in_percent'
author: Yaroslav Shmarov
tags: ruby
thumbnail: /assets/thumbnails/distance-of-time-in-percent.png
---

Imaging a progress bar to see what's left of your Netflix subscription.

We all know the [distance_of_time_in_words](https://apidock.com/rails/ActionView/Helpers/DateHelper/distance_of_time_in_words) method.

Now, we want something like `distance_of_time_in_percent`.

Here's a quick way to do it:

```ruby
# app/helpers/application_helper.rb
def distance_of_time_in_percent(from_time, current_time, to_time, precision = nil)
  precision ||= 0
  distance = to_time - from_time
  result = ((current_time - from_time) / distance) * 100
  result.round(precision).to_s + '%'
end
```

Voila! Now you can run something like: 
```ruby
# irb / rails c
current_time = Time.now
from_time = Time.now - 12*60*60*24
to_time = Time.now + 12*60*60*24

>> distance_of_time_in_percent(from_time, current_time, to_time)
=> '45%'

>> distance_of_time_in_percent(from_time, current_time, to_time, 1)
=> '45.4%'

>> distance_of_time_in_percent(from_time, current_time, to_time, precision = 3)
=> '45.456%'

>> distance_of_time_in_percent("01-01-2020".to_time, "31-06-202020".to_time, "31-12-2020".to_time, precision = 1)
=> '49.9%'
```

I've initially extracted this method from [gem distance_of_time_in_words](https://github.com/radar/distance_of_time_in_words#distance_of_time_in_percent).

Interestingly, methods like `"01-01-2020".to_time` or `number_with_precision` work in `rails`, but not `ruby`. Reminds me of [the tweet talking about **Rails** dialect of **Ruby** language](https://twitter.com/solnic29a/status/1491861149373145095)