---
layout: post
title: styling for true false values
author: Yaroslav Shmarov
tags: ruby-on-rails helpers bootstrap
thumbnail: /assets/thumbnails/truefalse.png
---

Add the helper below, and you will be able to style `true`/`false` values like this:

![final-result](/assets/2021-01-25-styling-for-true-false-values/boolean-colors.PNG)

app/helpers/application_helper.rb:
```
# boolean green or red

  def boolean_label(value)
    case value
    when true
      text = 'Yes'
      badge_color = 'badge bg-success text-light'
    when false
      text = 'No'
      badge_color = 'badge bg-danger text-light'
    end
    tag.span(text, class: badge_color)
  end
```
your view:
```
= boolean_label(user.confirmed?)
```