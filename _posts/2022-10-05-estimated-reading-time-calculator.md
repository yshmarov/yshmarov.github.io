---
layout: post
title: "Estimated reading time calculator with Ruby"
author: Yaroslav Shmarov
tags: ruby
thumbnail: /assets/thumbnails/ruby.png
---

Some blogging websites offer "estimated reading times".

Here's how you can create an "estimated reading time" calculator with Ruby.

Let's suppose, that the average reading time is 150 words per minute.

Than we just need to count the words in a text and devide the value by average:

```ruby
text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."

text.split.size
# => 91

def reading_time(text)
  word_count = text.split.size
  words_per_minute = 150
  (word_count.to_f / words_per_minute.to_f).round(1)
end

reading_time(text)
# => 0.6 (minutes)
```

That's it! 📚🧑‍🏫
