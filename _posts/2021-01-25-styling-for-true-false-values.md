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
      # content_tag(:span, "Yes", class: "badge badge-success")
      content_tag(:span, value, class: "badge badge-success")
    when false
      content_tag(:span, value, class: "badge badge-danger")
  end
end
```
your view:
```
= boolean_label(user.confirmed?)
```