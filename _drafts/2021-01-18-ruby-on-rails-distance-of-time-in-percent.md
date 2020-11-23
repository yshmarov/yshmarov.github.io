---
layout: post
title: 'Ruby on Rails: Quick tip: distance_of_time_in_percent method'
date: '2020-10-29T17:13:00.001+01:00'
author: yaro_the_slav
tags: 
modified_time: '2020-10-29T17:13:15.852+01:00'
thumbnail: https://lh3.googleusercontent.com/-n-D-2lOycQo/X5rp5U2ASYI/AAAAAAACFJw/Iu4rTg0PMn024ySS6G_RSYwfSIANssKlQCLcBGAsYHQ/s72-c/image.png
blogger_id: tag:blogger.com,1999:blog-5936476238571675194.post-4234308261857439706
---

Wouldn't it be cool a progress bar to see how much you have left of your Netflix subscription?


We all know the distance_of_time_in_words method.

Now, we want something like distance_of_time_in_percent.

Here's a quick way to do it:

add this to application_helper:

def distance_of_time_in_percent(from_time, current_time, to_time, options = {})
  options[:precision] ||= 0
  options = options_with_scope(options)
  distance = to_time - from_time
  result = ((current_time - from_time) / distance) * 100
  number_with_precision(result, options).to_s + '%'
end
Voila! Now you can run something like: 
>> distance_of_time_in_percent("01-01-2020".to_time, "31-06-202020".to_time, "31-12-2020".to_time, precision: 1)
=> '49.9%'
Source