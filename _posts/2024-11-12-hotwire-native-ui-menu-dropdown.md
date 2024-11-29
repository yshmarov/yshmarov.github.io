---
layout: post
title: Hotwire Native Bridge Nav (UIMenu) Component
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/turbo.png
---

[UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar) in SwiftUI is the native navbar, that can have a "Back" `<` navigation link, page title, or action buttons.

[UIMenu](https://developer.apple.com/documentation/uikit/uimenu) is a component that lets you open a small native dropdown:

![Hotwire Native UIMenu](/assets/images/hotwire-navive-bridge-nav-dropdown.gif)

You can add a UIMenu using **Hotwire Native Bridge**.

First, add the Bridge component to your Hotwire Native iOS app:

```swift
// NavComponent.swift
import HotwireNative
import UIKit

final class NavComponent: BridgeComponent {
    override class var name: String { "nav" }

    override func onReceive(message: Message) {
        guard let viewController else { return }
        addButton(via: message, to: viewController)
    }

    private var viewController: UIViewController? {
        delegate.destination as? UIViewController
    }

    private func addButton(via message: Message, to viewController: UIViewController) {
        guard let data: MessageData = message.data() else { return }

        let items: [UIAction] = data.items.map { item in

            UIAction(title: item.title,
                     image: UIImage(systemName: item.image),
                     attributes: item.destructive ? .destructive : [],
                     state: item.state == "on" ? .on : .off
            ) { (_) in
                self.onItemSelected(item: item)
            }
        }

        // build the menu item
        let image = UIImage(systemName: data.image)
        let menu = UIMenu(title: data.title, children: items)
        let menuItem = UIBarButtonItem(image: image, menu: menu)

        if data.side == "right" {
            viewController.navigationItem.rightBarButtonItem = menuItem
        } else {
            viewController.navigationItem.leftBarButtonItem = menuItem
        }
    }

    private func onItemSelected(item: MenuItem) {
        self.reply(
            to: "connect",
            with: SelectionMessageData(selectedIndex: item.index)
        )
    }
}

private extension NavComponent {
    struct MessageData: Decodable {
        let items: [MenuItem]
        let image: String
        let side: String
        let title: String
    }
    struct MenuItem: Decodable {
        let title: String
        let image: String
        let destructive: Bool
        let state: String
        let index: Int
    }
    struct SelectionMessageData: Encodable {
        let selectedIndex: Int
    }
}
```

Add a Stimulus controller in your Web app:

```js
// app/javascript/controllers/bridge/nav_controller.js
import { BridgeComponent, BridgeElement } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "nav"
  static targets = ["item"]

  connect() {
    super.connect()

    const items = this.itemTargets.map((item, index) => {
      const itemElement = new BridgeElement(item)

      return {
        title: itemElement.title,
        image: itemElement.bridgeAttribute("image") ?? "none",
        destructive: item.dataset.turboMethod === "delete",
        state: itemElement.bridgeAttribute("state") ?? "off",
        index
      }
    })

    const element = this.bridgeElement
    const title = element.bridgeAttribute("title") ?? ""
    const side = element.bridgeAttribute("side") || "left"
    const image = element.bridgeAttribute("image") || "none"

    this.send("connect", { items, title, image, side }, (message) => {
      const selectedIndex = message.data.selectedIndex
      const selectedItem = new BridgeElement(this.itemTargets[selectedIndex]);

      selectedItem.click()
    })
  }
}
```

Finally, define links and icons that should appear in UIMenu

```ruby
<%= tag.div data: { controller: 'bridge--nav', bridge_side: 'right', bridge_image: 'person.circle' } do %>
  <%= link_to 'Profile', edit_user_registration_path, data: { bridge__nav_target: 'item', bridge_image: 'person.circle' } %>
  <%= button_to 'Sign Out', destroy_user_session_path, method: :delete, data: { bridge__nav_target: 'item', bridge_image: 'return', turbo_method: :delete, turbo: true } %>
<% end %>
```

🚨 I tried using `link_to data: { turbo_method: :delete, turbo_confirm: "Sure?" }`, but it submitted even on clicking **Cancel** in the confirmation modal! This problem did not reoccur with `button_to`.

Notice that `bridge_side` can be `right` or `left`.

You can lookup icons to use in `SF Symbols` app.

Credit to beanman for [coming up](https://discord.com/channels/1042568983724966018/1042569530834178058/1302027871430246452) with this solution.

John Pollard also [talked about this component](https://www.slideshare.net/slideshow/johnpollard-hybrid-app-railsconf2024-pptx/268167413?utm_source=hotwireweekly&utm_medium=email&utm_campaign=week-20-new-turbo-native-videos-turbo-mount#43) in his RailsConf talk.
