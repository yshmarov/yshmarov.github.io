---
layout: post
title: Hotwire Native Bridge Component - Prompt to leave an AppStore review
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/turbo.png
---

Joe Masilotti recently [shared](https://x.com/joemasilotti/status/1855980993674653995/photo/2) his solution for invoking a prompt to leave an App Store review in a Hotwire Native app.

![Prompt to leave an AppStore review ](/assets/images/hotwire-native-leave-a-review-prompt.png)

Implementation guide:

Create a `ReviewPromptComponent` in your Hotwire Native iOS app:

```swift
// ReviewPromptComponent.swift
import HotwireNative
import StoreKit

class ReviewPromptComponent: BridgeComponent {
  override class var name: String { "review-prompt" }

  private var viewController: UIViewController? {
    delegate.destination as? UIViewController
  }

  override func onReceive(message: HotwireNative.Message) {
    if let scene = viewController?.view.window?.windowScene {
      SKStoreReviewController.requestReview(in: scene)
    }
  }
}
```

Stimulus controller to invoke the StoreReview prompt:

```js
// review_prompt_controller.js
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "review-prompt"

  connect() {
    super.connect()
    this.send("connect")
  }
}
```

Finally, initialize this stimulus controller anywhere in your HTML:

```html
<meta data-controller="bridge--review-prompt" />
```

> ⚠ You can ask a user to leave a review 3 times in 365 days.
> Do not display this component too often.
> Display it after a user has a "positive experience".

That's it!
