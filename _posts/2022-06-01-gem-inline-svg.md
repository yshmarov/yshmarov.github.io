---
layout: post
title: "Quick tip: Use gem inline_svg for importing custom SVGs"
author: Yaroslav Shmarov
tags: ruby-on-rails inline_svg svg
thumbnail: /assets/thumbnails/html.png
---

In some cases you don't want to use external SVG libraries like FontAwesome.

Instead, you might want to have your own SVGs.

You can import SVGs into your apps' assets folder:

```html
<!-- app/assets/images/svg/search.svg -->
<svg width="1em" height="1em" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M15.828 14.871l-4.546-4.545a6.34 6.34 0 10-.941.942l4.545 4.545a.666.666 0 00.942-.942zm-9.461-3.525a4.995 4.995 0 114.994-4.994 5 5 0 01-4.994 4.994z" fill="currentColor"/>
</svg>
```

```html
<!-- app/assets/images/svg/share-social.svg -->
<svg width="1em" height="1em" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12.0008 10.4998C11.7314 10.4997 11.4648 10.5542 11.2171 10.6601C10.9694 10.7659 10.7457 10.9208 10.5595 11.1155L5.93451 8.51328C6.0241 8.17685 6.0241 7.82283 5.93451 7.4864L10.5595 4.88422C10.8963 5.23339 11.3488 5.44778 11.8324 5.48724C12.3159 5.5267 12.7972 5.38851 13.1861 5.09857C13.5751 4.80863 13.845 4.38682 13.9452 3.91217C14.0455 3.43753 13.9693 2.9426 13.7308 2.52013C13.4924 2.09765 13.1081 1.77661 12.6499 1.61714C12.1917 1.45767 11.6911 1.47073 11.2419 1.65386C10.7927 1.83698 10.4256 2.17762 10.2095 2.61195C9.99341 3.04628 9.94308 3.5445 10.0679 4.01328L5.44295 6.61547C5.16668 6.32741 4.81055 6.12861 4.42037 6.04462C4.03018 5.96064 3.62379 5.99531 3.25348 6.14419C2.88317 6.29307 2.56586 6.54934 2.3424 6.88003C2.11893 7.21073 1.99951 7.60072 1.99951 7.99984C1.99951 8.39896 2.11893 8.78896 2.3424 9.11965C2.56586 9.45034 2.88317 9.70661 3.25348 9.85549C3.62379 10.0044 4.03018 10.039 4.42037 9.95506C4.81055 9.87108 5.16668 9.67227 5.44295 9.38422L10.0679 11.9864C9.96071 12.3901 9.98257 12.8173 10.1305 13.2079C10.2783 13.5986 10.5448 13.9331 10.8925 14.1646C11.2402 14.3961 11.6517 14.5129 12.0691 14.4987C12.4866 14.4844 12.8891 14.3398 13.2202 14.0852C13.5513 13.8305 13.7944 13.4786 13.9153 13.0788C14.0362 12.6789 14.0289 12.2513 13.8944 11.8558C13.7599 11.4604 13.5049 11.1169 13.1653 10.8738C12.8257 10.6306 12.4185 10.4998 12.0008 10.4998Z" fill="currentColor"/>
</svg>
```

Usually when I import an SVG, I set `fill` to `currentColor` and width/height in `em`, not `px`:

````diff
-fill="#FFFFFF"`
+fill="currentColor"
```

```diff
-width="16px" height="16px"
+width="1em" height="1em"
```

Now you can use [`gem inline_svg`](https://github.com/jamesmartin/inline_svg){:target="blank"} to render the SVGs:

```shell
# terminal
bundle add inline_svg
```

```ruby
# any view
<%= inline_svg_tag "svg/search.svg", class: "", style: "color: green;" %>
<%= inline_svg_tag "svg/share-social.svg", class: "", style: "color: red; background-color: green;" %>
```

Result:

![add-to-gitignore](/assets/images/inline-svg-gem.png)
