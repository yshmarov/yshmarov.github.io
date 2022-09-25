---
layout: post
title: "Double loading StimulusJS controllers"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails turbo stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

I've noticed that sometimes a stimulus controller gets loaded twice when opening a page:

![double connect stimulus controller](/assets/images/double-connect-stimulus-controller.gif)

It might be because when you open the page, it **first loads a cached version of the page**, and than loads the content.


### Reproduce

It can be easily reproduced by adding a stimulus controller that logs `connect` & `disconnect`, and initializing the controller on a page.

It happens when clicking a `link_to` or navigating back in browser history via `javascript:history.back()`.

```html
<!-- app/views/posts/show.html.erb -->
<div data-controller="hello"></div>
```

```js
// app/javascript/hello_controller.js
import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    console.log('hello on')
  }
  disconnect() {
    console.log('hello off')
  }
}
```

### Solutions

In some cases you might want to prevent this double-loading.

**Solution #1**

```diff
# app/views/posts/index.html.erb
-<%= link_to 'Posts', posts_path %>
+<%= link_to 'Posts', posts_path, data: { turbo: false } %>
```

This will prevent double-loading only when clicking a link. Not when clicking through cached browser history.

**Solution #2**

```diff
# with gem meta-tags
# app/controllers/posts_controller.rb
  def index
    @posts = Post.all
+   set_meta_tags 'turbo-cache-control' => 'no-cache'
  end
```

This is a general solution that will cause a whole page reload each time you visit.

That's it!
