---
layout: post
title: "Navigating Turbo Native: where to start"
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/strada.png
---

People don't like using web apps on a mobile browser. Installing a PWA can be unclear to an average user. Sometimes you just have to build a mobile app.

Turbo Native is the easiest way to turn your Rails app (that uses responsive CSS) into a mobile (iOS/Android) app.

[Turbo Native](https://turbo.hotwired.dev/handbook/native) is a framework for **wrapping web apps** that use [Hotwire/Turbo Drive](https://hotwired.dev) into mobile ([iOS](https://github.com/hotwired/turbo-ios) & [Android](https://github.com/hotwired/turbo-android)) apps.

[Strada](https://strada.hotwired.dev/handbook/introduction) is a tool to integrate native (iOS or Android) UI elements in your mobile app. It is just a UI improvement library within the Turbo Native ecosystem. You don't have to integrate Strada to make your Turbo Native app work.

### Resources

You can browse existing Turbo Native apps in the [Turbo Native Directory](https://turbonative.directory/).

Top resources:

- [Hotwire Native screencasts](https://superails.com/playlists/turbo-native) - learn step by step
- [Hotwire Native text series](https://blog.superails.com/tag/hotwire-native.html) - same as above, but in text
- [Gem `hotwire_native_rails`](https://github.com/yshmarov/hotwire_native_rails) - generate helpers to make your Rails app ready for Native

Conference talks worth watching:

- [Intro to Hotwire Native - Rails World 2024, Yaroslav Shmarov](https://superails.com/posts/yaroslav-shmarov-hotwire-native-rails-world-2024-lightning-talk-unofficial-recording?playlist=turbo-native)
- [Joe Masilotti - Just enough Turbo Native to be dangerous - Rails World 2023](https://www.youtube.com/watch?v=hAq05KSra2g)
- [Jay Ohms - Strada: Bridging the web and native worlds - Rails World 2023](https://www.youtube.com/watch?v=LKBMXqc43Q8)
- [RailsConf 2024 - Insights Gained from Developing a Hybrid Application Using Turbo Native by John Pollard](https://www.youtube.com/watch?v=xJO36dD9lj4)

Blogs about Turbo Native:

- [Joe Masilotti](https://masilotti.com/articles/)
- [William Kennedy](https://williamkennedy.ninja/posts/)
- [Miles Woodroffe](https://mileswoodroffe.com/tags/turbo-native)

Youtube playlists:

- [Joe Masilotti](https://www.youtube.com/@joemasilotti)
- [William Kennedy](https://www.youtube.com/@williamkennedy9)
- [Indigo Tech](https://www.youtube.com/watch?v=O9G0cQomrfQ&list=PL2jr-nMCjDOuzwrs4KiO3N5xnahHZherM)

Templates/example apps:

- [Official demo app](https://github.com/hotwired/turbo-ios/tree/main/Demo)
- Open source [Daily Log](https://github.com/joemasilotti/daily-log)
- Open source [Northwind](https://github.com/matthewblott/northwind-on-rails)
- Paid [Jumpstart Pro iOS](https://jumpstartrails.com/ios) - has bottom tab navigation, push notifications, native sign up screen, can integrate google oauth. **This is not a Jumpstart endorsement.**

[Joe Masilotti Discord](https://discord.gg/xh37SthZ)

### Before you write any code

1. Download Xcode - the app for developing iOS apps.
2. Clone [hotwired/turbo-ios](https://github.com/hotwired/turbo-ios), run `open Demo/Demo.xcodeproj/`.
3. Play around with the example native app

### Get started coding!

1. Run your `rails s` on any Rails 7 app that has Turbo Drive enabled
2. Follow the [Quick Start Guide](https://github.com/hotwired/turbo-ios/blob/main/Docs/QuickStartGuide.md)
3. Or even better, use the Quick Start Guide from [the Turbo Navigator branch](https://github.com/hotwired/turbo-ios/pull/158). Hopefully this gets merged soon!
4. Set `URL` in `SceneDelegate.swift` to `http://localhost:3000` and see how your app looks on mobile!

That's a good start!
