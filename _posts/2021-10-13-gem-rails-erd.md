---
layout: post
title: "Generate Entity-Relationsip-Diagrams (ERD) from a Rails app"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails erd
thumbnail: /assets/thumbnails/polymorphism-sign.png
---

Use [gem rails-erd](https://github.com/voormedia/rails-erd) to generate Entity-Relationship-Diagrams (ERD) from your Rails app

### Usage

1. Add the gem to Gemfile
```ruby
gem 'rails-erd', group: :development
```

2. Install graphviz dependency in the console
```sh
sudo apt-get install graphviz
```

3. Now when you run
```sh
bundle exec erd
```

It will generate `erd.pdf` in the root folder of your Rails app.

Here are some examples of what it can look like:

![rails-erd-pdf](/assets/images/erd-view.png)

### Advanced usage

You can also create an `.erdconfig` file in the root folder [and add some configs](https://github.com/voormedia/rails-erd#configuration)
