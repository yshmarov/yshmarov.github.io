---
layout: post
title: "🛑🇷🇺 Block access to your software from Russia IPs"
author: Yaroslav Shmarov
tags: rails Ukraine rUssia
thumbnail: /assets/thumbnails/rails-logo.png
---

Russian Terrorist Army has attacked my country. It is bombing my hometown (Chernihiv). It is threatening life of my family. My grandmother is in a village occupied by Russians. She has no access to food an help.

As a software developer, this might be one of the easiest things you can do:

🛑 Block access to your software to anybody from Russia IPs 🛑

![block software from russia](assets/images/block-software.png)

Complete technological embargo.

If you're running a Ruby on Rails app, it takes just one gem and one before_action to do:

```ruby
bundle add geocoder

request.ip # => 233.543.123.235
request.location.country # => RU

# app/controllers/application_controller.rb
before_action do
  if request.location.country.eql?("RU")
    redirect_to "https://www.ukr.net/"
  end
end
```

Resources:
* [inspired by this answer on Stackoverflow](https://stackoverflow.com/a/13478695){:target="blank"}
* [gem geocoder](https://github.com/alexreisner/geocoder){:target="blank"}

**Update**: [@rameerez has created a gem](https://twitter.com/rameerez/status/1497522706274996224) that blocks all requests from Russia.
