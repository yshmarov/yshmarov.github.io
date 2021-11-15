---
layout: post
title: "Tip: Automatically annotate rails views"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails action-view viewcomponent
thumbnail: /assets/thumbnails/html.png
---

PROBLEM: When your application grows, and your views become more complex, it can be hard to know where an element on an HTML page is rendered from.

There's a simple solution!

![Automatically annotate rails views](/assets/images/annotate-views.png)

Just add this line:

```diff
# config/environments/development.rb
  # Annotate rendered view with file names.
--  # config.action_view.annotate_rendered_view_with_filenames = true
++  config.action_view.annotate_rendered_view_with_filenames = true
```

Works for:
* templates
* partials
* ViewComponents !!!

Resources:
* [Github rails/rails PR](https://github.com/rails/rails/pull/38848){:target="blank"}
* [Reddit discussion](https://www.reddit.com/r/rails/comments/qtsaj4/adding_file_paths_to_every_view_in_rails_in_dev/){:target="blank"}
