---
layout: post
title: Build a Trello clone with Ruby on Rails, RankedModel and jQuery Sortable
author: Yaroslav Shmarov
tags: ruby-on-rails jquery ranked-model drag-and-drop sortable
thumbnail: /assets/thumbnails/trello.png
---

It takes half an hour and 9 commits to build a basic Trello clone with Ruby on Rails!

Result:

![micro-trello-demo](/assets/2020-08-23-ruby-on-rails-sexy-basic-trello-clone/micro-trello-demo.gif)

[Source code](https://github.com/yshmarov/micro-trello){:target="blank"}

Tools:

* Rails 6
* [gem ranked-model](https://github.com/mixonic/ranked-model){:target="blank"}
* [jquery-ui-sortable](https://jqueryui.com/sortable/){:target="blank"}

Features: 
* create Lists
* create Tasks
* sort Lists 
* sort Tasks
* move Tasks between Lists
* persist changes in the database
