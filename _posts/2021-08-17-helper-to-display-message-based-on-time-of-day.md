---
layout: post
title: "Quick tip: Helper to display different text based on time of day"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails helpers rspec
thumbnail: /assets/thumbnails/clock.png
---

Sometimes in the application views or emails you will want to display a different message to users based on time of day. 

Here's a quick easy way to do it:

app/helpers/greetings_helper.rb

```ruby
module GreetingsHelper
  def greeting
    now = Time.zone.now
    if now.between?(now.beginning_of_day, now.noon)
      'Good Morning'
    elsif now.between?(now.noon, now.change(hour: 17, min: 30))
      'Good Afternoon'
    else
      'Good Evening'
    end
  end
end
```

Will display as follows:

```ruby
# Time.zone.now = 07:00
# greeting
# => Good Morning

# Time.zone.now = 13:00
# greeting
# => Good Afternoon

# Time.zone.now = 18:00
# greeting
# => Good Evening
```

Test it:

spec/helpers/greetings_helper_spec.rb

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GreetingsHelper, type: :helper do
  describe '#greeting' do
    it 'displays Good Morning before noon' do
      Timecop.freeze(Time.zone.now.change(hour: 10))
      expect(helper.greeting).to eq 'Good Morning,'
    end

    it 'displays Good Afternoon after noon' do
      Timecop.freeze(Time.zone.now.change(hour: 15))
      expect(helper.greeting).to eq 'Good Afternoon,'
    end

    it 'displays Good Evening after 5:30pm' do
      Timecop.freeze(Time.zone.now.change(hour: 20))
      expect(helper.greeting).to eq 'Good Evening,'
    end
  end
end
```
