---
layout: post
title: "StimulusJS social SHARE button"
author: Yaroslav Shmarov
tags: stimulusjs social-share
thumbnail: /assets/thumbnails/stimulus-logo.png
---

If you are building a PWA, you might want to still allow users toto share an URL to current page, so that another user can open it in a browser.

You could add a [copy URL to clipboard]({% post_url 2022-11-03-stimulus-copy-to-clipboard %}) button, but a better approach would be to use the [Browser Navigator API](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/share).

Here's how it looks on desktop:

![Navigator API social-share-desktop](/assets/images/social-share-desktop.png)

Mobile:

![Navigator API social-share-mobile](/assets/images/social-share-mobile.jpeg)

Let's build the share button!

```shell
rails g stimulus social-share
```

```js
// app/javascript/controllers/social_share_controller.js
import { Controller } from "@hotwired/stimulus"
// <!-- Social Share Button -->
export default class extends Controller {
  static values = { url: String }

  // hide the share button if it's not supported by a browser
  connect() {
    if (!navigator.share) {
      this.element.hidden = true;
    }
  }

  share(event) {
    // prevent form submit & redirect
    event.preventDefault();
    // share!
    navigator.share({url: this.urlValue});
  }
}
```

Finally, add this button to any (or all) URLs in your app:

```ruby
button_to 'Share', '#', data: { controller: 'social-share', social_share_url_value: request.url, action: 'click->social-share#share'}
```

That's it!
