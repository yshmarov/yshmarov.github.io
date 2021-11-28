---
layout: post
title: "Emoji select with `gem unicode-emoji`"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails unicode emoji
thumbnail: /assets/thumbnails/html.png
---

In this example we:
* select an emoji **with** a label
* save the emoji **without** the label to the database

![flag emoji select](/assets/images/flag-emoji-select.gif)

### HOWTO:

* add the gems:

```ruby
# Gemfile
gem "unicode-emoji" # emoji list and regex (for validations)
gem "unicode-sequence_name" # emoji names
```

* get the data you need;
* for example, flag-country mapping:

```ruby
# app/helpers/emoji_helper.rb
module EmojiHelper
  # ["🇦🇨 Ascension Island", "🇦🇩 Andorra"]...
  EMOJI_LIST = Unicode::Emoji.list("Flags")["country-flag"].map do |c|
    "#{c} #{Unicode::SequenceName.of(c).delete_prefix('FLAG:').downcase.gsub(/\b('?[^0-9])/) do
      Regexp.last_match(1).capitalize
    end }"
  end

  # [["🇦🇨 Ascension Island", "🇦🇨"], ["🇦🇩 Andorra", "🇦🇩"]...
  def emoji_for_select
    EMOJI_LIST.map do |k|
      [k, k.split.first]
    end
  end
end
```

* add the collection select to any column:

```ruby
# app/views/posts/_form.html.erb
<%= form.select :icon, emoji_for_select, { include_blank: "Select a flag" }, {} %>
```

That's it!
