---
layout: post
title: "Navigating Turbo Native: where to start"
author: Yaroslav Shmarov
tags: turbo-native
thumbnail: /assets/thumbnails/strada.png
---

People don't like using web apps on a mobile browser. Installing a PWA can be unclear to an average user. Sometimes you just have to build a mobile app.

Turbo Native is the easiest way to turn your Rails app (that uses responsive CSS) into a mobile (iOS/Android) app.

[Turbo Native](https://turbo.hotwired.dev/handbook/native) is a framework for **wrapping web apps** that use [Hotwire/Turbo Drive](https://hotwired.dev) into mobile ([iOS](https://github.com/hotwired/turbo-ios) & [Android](https://github.com/hotwired/turbo-android)) apps.

[Strada](https://strada.hotwired.dev/handbook/introduction) is a tool to integrate native (iOS or Android) UI elements in your mobile app. It is just a UI improvement library within the Turbo Native ecosystem. You don't have to integrate Strada to make your Turbo Native app work.

### Resources

You can browse existing Turbo Native apps in the [Turbo Native Directory](https://turbonative.directory/).

Conference talks worth watching:
- [Joe Masilotti - Just enough Turbo Native to be dangerous - Rails World 2023](https://www.youtube.com/watch?v=hAq05KSra2g)
- [Jay Ohms - Strada: Bridging the web and native worlds - Rails World 2023](https://www.youtube.com/watch?v=LKBMXqc43Q8)
- [RailsConf 2024 - Insights Gained from Developing a Hybrid Application Using Turbo Native by John Pollard](https://www.youtube.com/watch?v=xJO36dD9lj4)

Blogs about Turbo Native:
- [Joe Masilotti](https://masilotti.com/articles/)
- [Miles Woodroffe](https://mileswoodroffe.com/tags/turbo-native)
- [William Kennedy](https://williamkennedy.ninja/posts/)

Youtube playlists:
- [Indigo Tech](https://www.youtube.com/watch?v=O9G0cQomrfQ&list=PL2jr-nMCjDOuzwrs4KiO3N5xnahHZherM)
- [William Kennedy](https://www.youtube.com/@williamkennedy9)

Templates/example apps:
- Free [Daily Log](https://github.com/joemasilotti/daily-log)
- Paid [Jumpstart Pro iOS](https://jumpstartrails.com/ios) - has bottom tab navigation, push notifications, native sign up screen, can integrate google oauth

### Get started coding!

- Follow the [Quick Start Guide](https://github.com/hotwired/turbo-ios/blob/main/Docs/QuickStartGuide.md)
- Or even better, use the Quick Start Guide from [the Turbo Navigator branch](https://github.com/hotwired/turbo-ios/pull/158). Hopefully this gets merged soon!
- Point the URL to [this demo app](https://github.com/hotwired/turbo-native-demo)
