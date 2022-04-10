---
layout: post
title: "Fontawesome + Importmaps + Rails 7"
author: Yaroslav Shmarov
tags: ruby-on-rails fontawesome
thumbnail: /assets/thumbnails/fontawesome-logo.png
---

I love [Fontawesome free icon library](https://fontawesome.com/search?m=free){:target="blank"}

![fontawesome-icons-gif.gif](/assets/images/fontawesome-icons-gif.gif)

I've been using it in most of my projects over the last 7 years.

Here's how you can make it work in Rails 7 + importmaps.

So, you need to import fontawesome from npm. If you visit [fontawesome npm homepage](https://www.npmjs.com/package/@fortawesome/fontawesome-free){:target="blank"}, you will see a command `npm i @fortawesome/fontawesome-free`.

For importmaps you can run:

```ruby
# console
./bin/importmap pin @fortawesome/fontawesome-free
```

This will generate the following code:

```diff
# config/importmap.rb
++pin "@fortawesome/fontawesome-free", to: "https://ga.jspm.io/npm:@fortawesome/fontawesome-free@6.1.1/js/fontawesome.js"
```

Change the line:

```diff
# config/importmap.rb
--pin "@fortawesome/fontawesome-free", to: "https://ga.jspm.io/npm:@fortawesome/fontawesome-free@6.1.1/js/fontawesome.js"
++pin '@fortawesome/fontawesome-free', to: 'https://ga.jspm.io/npm:@fortawesome/fontawesome-free@6.1.1/js/all.js'
```

Include fontawesome in your js:

```js
// app/javascript/application.js
import "@fortawesome/fontawesome-free"
```

Now you can use icons in your code:

```ruby
# app/views/any_file.html.erb
<i class="fa-solid fa-flag"></i>
<i class="fa-brands fa-amazon"></i>
<i class="fa-regular fa-bell"></i>
```

That's it!

Bonus: [style fontawesome icons](https://fontawesome.com/v6/docs/web/style/styling){:target="blank"}

It's super easy to add `size`, `animation`, `rotation`:

```ruby
# app/views/any_file.html.erb
<i class="fa-solid fa-refresh fa-2xl fa-spin"></i>
<i class="fa-solid fa-gem fa-rotate-180"></i>
<i class="fa-solid fa-gem fa-rotate-by" style="color: green; --fa-rotate-angle: 45deg"></i>
<i class="fa-brands fa-youtube" style="color: red;"></i>
<i class="fa-regular fa-bell fa-beat"></i>
```

[Here is an alternative solution](https://pablofernandez.tech/2022/03/12/using-font-awesome-6-in-a-rails-7-project-that-uses-importmaps/){:target="blank"}
