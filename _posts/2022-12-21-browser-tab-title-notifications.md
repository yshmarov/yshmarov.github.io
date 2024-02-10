---
layout: post
title: "Browser tab title notifications"
author: Yaroslav Shmarov
tags: stimulusjs html rails
thumbnail: /assets/thumbnails/linkedin-bell.png
youtube_id: CmNj_BZGGUg
---

The other day I was browsing LinkedIn and I thought of the best way to reproduce it's iconic way of showing the new notifications counter in the browser tab:

![linkedin-tab-preview.png](assets/images/linkedin-tab-preview.png)

Notice the different favicon (with a red circle), and the title text (with notifications count).

### 1. Display Notifications count

Assuming you have a `current_user` that `has_many :notifications`. Notifications model has `seen:boolean, default: false`.

You would need two separate favicons:

Default favicon

![linkedin.png](assets/images/linkedin.png)

favicon with a notifications symbol

![linkedin-bell.png](assets/images/linkedin-bell.png)

Now you can set a different `favicon` and `title` each time you refresh/revisit a page in your application:

```diff
# app/views/layouts/application.html.erb

-<title>LinkedIn</title>
+<% new_notifications = current_user.notifications.where(seen: [false, nil]) %>
+<% if new_notifications.any? %>
+  <%= favicon_link_tag asset_path('linkedin-notify.png') %>
+  <title>(<%= new_notifications.count %>)LinkedIn</title>
+<% else %>
+  <%= favicon_link_tag asset_path('linkedin.png') %>
+  <title>LinkedIn</title>
+<% end %>
```

No notifications:

![linkedin-notification-no.png](assets/images/linkedin-notification-no.png)

With notifications:

![linkedin-notification-yes.png](assets/images/linkedin-notification-yes.png)

### 2. Blinking browser tab title

If you want to be more persuasive, you can make the tab blink

![linkedin-notifications-gif.gif](assets/images/linkedin-notifications-gif.gif)

```diff
# app/views/layouts/application.html.erb

<% new_notifications = current_user.notifications.where(seen: [false, nil]) %>
<% if new_notifications.any? %>
  <%= favicon_link_tag asset_path('linkedin-bell.png') %>
-  <title>(<%= new_notifications.count %>)LinkedIn</title>
+  <title data-controller="text-blink" data-text-blink-newtitle-value="(<%= new_notifications.count %>) Alerts">LinkedIn</title>
<% else %>
  <%= favicon_link_tag asset_path('linkedin.png') %>
  <title>LinkedIn</title>
<% end %>
```

To remove the blinking effect when there are no notifications, you have to explicitly disconnect the controller:

```js
// app/javascript/controllers/text_blink_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    newtitle: String
  }

  connect() {
    // var newTitle = "(3) Alerts"
    // var oldTitle = "LinkedIn"
    var newTitle = this.newtitleValue
    var oldTitle = document.title
    var blink = function() { document.title = document.title == newTitle ? oldTitle : newTitle; }
    this.myInterval = setInterval(blink, 1000)
  }

  disconnect() {
    clearInterval(this.myInterval);
  }
}
```

### 3. Refresh without page reload

You can move the page title into a partial, and update it each time a new notification is created using Turbo Stream Broadcasts:

```ruby
<%#= turbo_stream_from (current_user, :global_notifications) %>
<%= turbo_stream_from :global_notifications %>
```

```ruby
# app/controllers/notifications_controller.rb
@notification.save
# Turbo::StreamsChannel.broadcast_replace_to([current_user, :global_notifications],
Turbo::StreamsChannel.broadcast_replace_to(:global_notifications,
                                          target: 'page-title',
                                          partial: "shared/page_title")
```

Anyway, this particular feature does not look like top priority functionality. It does not matter to me.

So,

That's it! 🎉🥳🍾
