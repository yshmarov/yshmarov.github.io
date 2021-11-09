---
layout: post
title: "#11 Turbo Frames - Load content only when a dropdown is opened"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo turbo-frames dropdowns
thumbnail: /assets/thumbnails/turbo.png
---

![details-turbo-eager-loading](/assets/images/details-turbo-eager-loading.gif)

If a page has a turbo frame with lazy loading, the lazy loading will occur only when the frame element becomes not "hidden".

If you than change the state back to hidden, the loaded content will stay.

```ruby
<details>
  <summary>Details</summary>
  <%= turbo_frame_tag 'new_inbox', src: new_inbox_path, loading: :lazy do %>
    Loading...
  <% end %>
</details>
```

=> This is great for having a lot of content that should not be directly visible. 

Think Tabs, Dropdowns, Modals.

[`details` HTML tag](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details){:target="blank"}
