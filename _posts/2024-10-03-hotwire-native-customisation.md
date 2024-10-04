---
layout: post
title: Hotwire Native iOS - Tabs and design customisation
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/turbo.png
---

![Hotwire Native customised example](/assets/images/hotwire-native-customisation.png)

### Add Tab bar

I think it's one of the most requested/improtant features for a classic Rails app that is turned mobile.

Tabs behave like browser tabs = navigation history is separete within each tab.

The tab titles will be overriden by the page HTML `<title>` if present.

Download and use SF Symbols app to select icons that work best for you.

The best boilerplate to start building a Native app is the [Demo app](https://github.com/hotwired/hotwire-native-ios/tree/main/Demo).

```js
// Demo/SceneController.swift
class TabBarController: UITabBarController {
    private let navigators: [Navigator]
    
    init(navigators: [Navigator]) {
        self.navigators = navigators
        super.init(nibName: nil, bundle: nil)
        
        viewControllers = navigators.map { $0.rootViewController }
        
        // Customize tab bar items
        viewControllers?[0].tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        viewControllers?[1].tabBarItem = UITabBarItem(title: "Posts", image: UIImage(systemName: "play.circle"), tag: 1)
        viewControllers?[2].tabBarItem = UITabBarItem(title: "Playlists", image: UIImage(systemName: "list.number"), tag: 2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

Assuming you have paths `/posts` & `/playlists` in your app:

```diff
# Demo/SceneController.swift
-    private lazy var navigator = Navigator(pathConfiguration: pathConfiguration, delegate: self)
+    private lazy var navigators: [Navigator] = {
+        (0..<3).map { _ in Navigator(pathConfiguration: pathConfiguration, delegate: self) }
+    }()
+    private lazy var tabBarController = TabBarController(navigators: navigators)

...

-        navigator.route(rootURL)
+        navigators[0].route(rootURL)
+        navigators[1].route(rootURL.appendingPathComponent("/posts"))
+        navigators[2].route(rootURL.appendingPathComponent("/playlists"))

...

-        window.rootViewController = navigator.rootViewController
+        window.rootViewController = tabBarController
```

⚠️ You might have to delete the example code for "Authentication" and "Numbers", so that no errors pop up.

### Customize tab bar design

Use [uicolor.io](https://www.uicolor.io/) to convert Hex colors to Swift.

```js
// Demo/SceneController.swift
extension UITabBar {
    static func configureWithOpaqueBackground() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        // tabBarAppearance.backgroundColor = .systemGray5
        tabBarAppearance.backgroundColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1.00)
        
        appearance().standardAppearance = tabBarAppearance
        appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
```

```diff
# Demo/SceneController.swift
+  UITabBar.configureWithOpaqueBackground()
  window.rootViewController = tabBarController
```

### Customize header

- Make header not transparent
- Change background color
- Change text color

```js
// Demo/SceneController.swift
extension UINavigationBar {
    static func configureWithOpaqueBackground() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        // navigationBarAppearance.backgroundColor = .systemBlue
        navigationBarAppearance.backgroundColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1.00)
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        appearance().scrollEdgeAppearance = navigationBarAppearance
        appearance().standardAppearance = navigationBarAppearance
    }
}
```

above 

```diff
# Demo/SceneController.swift
+  UINavigationBar.configureWithOpaqueBackground()
  window.rootViewController = tabBarController
```

### Disable force touch

Force Touch = press and hold a link for a long time to open it as a preview in an in-app browser. This feels like a browser, not app behaviour.

![Hotwire Native force touch example](/assets/images/hotwire-native-force-touch-example.png)

Let's disable it.

```diff
# Demo/SceneController.swift
...
        configureBridge()
+        Hotwire.config.makeCustomWebView = { configuration in
+            let webView = WKWebView(frame: .zero, configuration: configuration)
+            webView.allowsLinkPreview = false
+            Bridge.initialize(webView)
+            return webView
+        }
        configureRootViewController()
...
```

That's it for now!
