---
layout: post
title: 'Ruby on Rails: Quick tip: distance_of_time_in_percent method'
author: Yaroslav Shmarov
tags: 
- ruby on rails
- rails
thumbnail: https://cdn1.iconfinder.com/data/icons/loan-and-investment-plan/64/Clock-date-time-percent-512.png
---

# TODOYARO

Wouldn't it be cool a progress bar to see how much you have left of your Netflix subscription?

We all know the distance_of_time_in_words method.

Now, we want something like distance_of_time_in_percent.

Here's a quick way to do it:

add this to application_helper:
```
def distance_of_time_in_percent(from_time, current_time, to_time, options = {})
  options[:precision] ||= 0
  options = options_with_scope(options)
  distance = to_time - from_time
  result = ((current_time - from_time) / distance) * 100
  number_with_precision(result, options).to_s + '%'
end
```
Voila! Now you can run something like: 
```
>> distance_of_time_in_percent("01-01-2020".to_time, "31-06-202020".to_time, "31-12-2020".to_time, precision: 1)
=> '49.9%'
```
Sources:
[gem distance_of_time_in_words](https://github.com/radar/distance_of_time_in_words)
[rails docs](https://apidock.com/rails/ActionView/Helpers/DateHelper/distance_of_time_in_words)
