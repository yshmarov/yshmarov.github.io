---
layout: post
title: Hotwire Native CSS and TailwindCSS variants (conditionals)
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/turbo.png
---

When building [Hotwire Native](https://native.hotwired.dev/) apps, often you will want to have different CSS for native and desktop apps.

We can achieve it by addin custom variants like `non-turbo-native:` & `turbo-native:`.

```html
<div class="non-turbo-native:hidden">
  Visible only on Native
</div>
<div class="turbo-native:hidden">
  Visible only on Desktop
</div>
```

### CSS

```css
/* application.css */
body.turbo-native .turbo-native:hidden {
  display: none;
}
```

```html
<body class="<%%= "turbo-native" if turbo_native_app? %>">
<h1 class="turbo-native:hidden">Hello, world!</h1>
```

Source: [masilotti.com](https://masilotti.com/hide-web-rendered-content-on-turbo-native-apps/)

### Tailwind

To enable this, update your tailwind config file:

```diff
# config/tailwind.config.js
const defaultTheme = require('tailwindcss/defaultTheme')
+const plugin = require('tailwindcss/plugin')

module.exports = {
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
+    plugin(function({ addVariant }) {
+      addVariant("turbo-native", "html[data-turbo-native] &"),
+      addVariant("non-turbo-native", "html:not([data-turbo-native]) &")
+    })
  ],
}
```

And **conditionally** add `data-turbo-native` to your `<html>` tag:

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def platform_identifier
    'data-turbo-native' if turbo_native_app?
  end
end
```

```diff
# app/views/application.html.erb
-<html>
+<html <%= platform_identifier %>>
```

That's it! Now you can apply the CSS variant:

```html
<div class="non-turbo-native:hidden">
  Visible only on Native
</div>
<div class="turbo-native:hidden">
  Visible only on Desktop
</div>

<div class="turbo-native:bg-black turbo-native:text-white">
  Turbo Native
</div>
<div class="non-turbo-native:bg-black non-turbo-native:text-white">
  Non Turbo Native
</div>
```

### Enable for a block

```js
// config/tailwind.config.js
      addVariant('mobile', '&[data-turbo-native="true"]'),
      addVariant('non-mobile', '&[data-turbo-native="false"]'),
```

```html
<div data-turbo-native="true" class="mobile:bg-black non-mobile:bg-red-400">
  This is mobile
</div>

<div data-turbo-native="false" class="mobile:bg-black non-mobile:bg-red-400">
  This is non-mobile
</div>
```

[Subscribe to SupeRails.com](https://superails.com/pricing) for more Hotwire Native content!

That's it for now!
