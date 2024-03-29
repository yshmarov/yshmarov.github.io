---
layout: post
title: "Convert integer to time (hh:mm:ss)"
author: Yaroslav Shmarov
tags: ruby
thumbnail: /assets/thumbnails/clock.png
---

Usually when you want to store a `time` field I recommend not storing time, but instead using a `datetime` field.

That way you won't encounter many unexpected problems.

But if you do have to store time like `19:30:00`, you might as well store it in `integer`.

Here's how you can convert `integer` to `hh:mm:ss`

For example, follow along to see how to convert 54,234 seconds to hours, minutes, and seconds.

### THE SHORT WAY

```ruby
def seconds_to_time(seconds)
  # t = 236 # seconds
  Time.at(seconds).utc.strftime('%H:%M:%S')
  # => "00:03:56"
end

def time_to_seconds(time)
  # t = '00:03:56'
  h = time.split(':').first.to_f
  m = time.split(':').second.to_f
  s = time.split(':').third.to_f
  tts = (h * 60 * 60) + (m * 60) + s
  tts.to_i
  # => 236
end
```

### THE LONG WAY

```ruby
# First, find the number of whole hours
now = 54234
hours = now / 3600
# => 15

# Find the number of whole minutes
raw_hours = now / 3600.to_f
# => 15.065
raw_minutes = raw_hours - hours
# => 0.0649
full_minutes = raw_minutes * 60
# => 3.89
minutes = full_minutes.to_i
# => 3

# Find the remaining seconds
raw_seconds = full_minutes - minutes
# => 0.89
seconds = (raw_seconds * 60).round
# => 54

# Finish up by rewriting as HH:MM:SS
time = [hours, minutes, seconds].join(':')
# => "15:3:54"
```

That's it!
