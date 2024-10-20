---
layout: post
title: Sentiment Analysis. Analyze Udemy course reviews
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: https://about.udemy.com/wp-content/uploads/2017/10/NewUlogo-large-1.png
---

I [used to](https://www.udemy.com/user/ya-shm/) create Udemy courses.

Now I downlaoded all my Udemy reviews and ran a sentimnent analysis on them using gem [7compass/sentimental](https://github.com/7compass/sentimental)

Here's how I ran it, and here are the results:

```ruby
require 'csv'

file_path = "db/data/Udemy_Reviews_Export_2024-10-20_20-13-07.csv"

# CSV: get an array of all ratings

ratings = []

CSV.foreach(file_path, headers: true) do |row|
  rating = row['Rating']
  ratings << rating.to_f unless rating.nil?
end

average_rating = ratings.sum / ratings.size

average_rating.round(2)

# CSV: get an array of all comments

comments = []

CSV.foreach(file_path, headers: true) do |row|
  comment = row['Comment']
  comments << comment unless comment.nil? || comment.strip.empty?
end

# Get average sentiment of comments

sentiment_counts = { positive: 0, negative: 0, neutral: 0 }

comments.each do |comment|
  sentiment = analyzer.sentiment(comment)
  sentiment_counts[sentiment] += 1
end

# sentiment_counts
# => {:positive=>87, :negative=>16, :neutral=>10}

# Get average sentiment score of comments

total_score = 0.0

comments.each do |comment|
  score = analyzer.score(comment)
  total_score += score
end

average_score = total_score / comments.size

# average_score
# => 1.0640205752212393
```

I'm quite happy with the results!

