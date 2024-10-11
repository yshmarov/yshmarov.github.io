---
layout: post
title: Hotwire Native TailwindCSS variants (conditionals)
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

[Subscribe to SupeRails.com](https://superails.com/pricing) for more Hotwire Native content!

That's it for now!
