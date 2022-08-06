---
layout: post
title: HAML or ERB for Ruby on Rails development in 2021?
author: Yaroslav Shmarov
tags: haml erb ruby rails
thumbnail: /assets/thumbnails/haml.png
---

I'm often asked why I use HAML for my projects.

2 Reasons:
* easier to read than `*.html.erb`
* easier to write than `*.html.erb`
* wide adoption: some time ago [I did a poll on **r/rails**](https://www.reddit.com/r/rails/comments/gs0x4b/htmlerb_vs_htmlhaml_vs_htmlslim_which_one_do_you/){:target="blank"} to see it's pupularity. Results:

![haml-vs-erb](/assets/2021-01-04-rails-erb-or-haml/haml-vs-erb.png)

Clearly, HAML is a modern and popular choice for web development with Ruby on Rails 6.

VERY useful websites that help converting bulk code **from** haml to erb, that I use on a daily basis:

* [haml2erb.org](haml2erb.org/){:target="blank"}

### 2022 Update: **Back 2 `.erb`**

After years of using [and advocating for]({% post_url 2021-01-04-rails-erb-or-haml %}){:target="blank"} `HAML`, I'm switching back to `ERB`.

Why? Not because I like it more.

1. Because it is more popular, thus lowering the entry barrier for people reading my code. (Stupid reason)
2. Because in the new world of StimulusJS & Hotwire Turbo we now have to write a lot of `data` attributes and `dom_id`s, and I want to keep everything consistent. (Better reason)
3. Because I had to get used to using it at work. 

Althrough, haml-like logical nesting will forever be a must-have in my code. And if I had to draft an HTML page right away (without a framework), I would be able to do it faster and more elegantly in HAML. Haml is a viable way to writing beautiful HTML, that can be used way beyond the context of Ruby on Rails.

That's life.
