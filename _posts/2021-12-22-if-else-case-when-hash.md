---
layout: post
title: "TIP: if-else, case-when, hash?"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails tiny-tip
thumbnail: /assets/thumbnails/ruby.png
---

One of the most primitive things you do when coding is writing `if-else` conditionals.

When I just started, this looked perfect to me:

### 1. 2015: `If-Elsif`

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  def status_color(status)
    if status == 'incoming'
      'grey'
    elsif status == 'todo'
      'orange'
    elsif status == 'done'
      'green'
    elsif status == 'spam' || status == "error"
      'red'
    else
      'black'
    end
  end
end
```

```ruby
Task.status_color('done')
=> 'green'
```

One beautiful day, I learnt about
[Rubocop](https://github.com/rubocop/rubocop){:target="blank"}
and it introduced me to
[`case-when`](https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Style/CaseLikeIf){:target="blank"}

### 2. 2017: `Case-When`

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  def status_color(status)
    case status
    when 'incoming'
      'grey'
    when 'todo'
      'orange'
    when 'done'
      'green'
    when 'spam', 'error'
      'red'
    else
      'black'
    end
  end
end
```

```ruby
Task.status_color('done')
=> 'green'
```

A bit cleaner and less duplication, right?

However, in some cases you can just define a `hash` and get a value from a hash:

### 3. 2021: `hash[key] => value`

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  COLOR_STATUSES = { incoming: 'grey', todo: 'orange', done: 'green', spam: 'red', error: 'red' }.freeze
end
```

```ruby
Task::COLOR_STATUSES['todo'] || 'black'
=> 'green'
# Task::COLOR_STATUSES[@task.status.to_sym] || 'black'
```

In some cases this is better and simpler!

[Here's a real-world scenario](https://github.com/yshmarov/askdemos/pull/1/files#diff-7cb3f33ed8cd7f9d71058dc2794a0f49c4ff135156fac2c3318840fdd2431040R4){:target="blank"}
where this approach is better
(kudos [@secretpray](http://github.com/secretpray/){:target="blank"})
