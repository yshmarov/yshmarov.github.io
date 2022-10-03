---
layout: post
title: "Bootstrap 5 + Rails 7"
author: Yaroslav Shmarov
tags: ruby-on-rails bootstrap
thumbnail: /assets/thumbnails/bootstrap.png
---

You will need to use the gem [cssbundling-rails](https://github.com/rails/cssbundling-rails) to make bootstrap work on Rails 7.

### Option 1: importmaps + cssbundling

In rails 7, when you create a new rails app, importmaps will be used by default. 

You can forget about Node.js and Webpack!

```ruby
# console
rails new myapp1 -d postgresql
```

Next, install `gem cssbundling-rails`:

```ruby
# console
./bin/bundle add cssbundling-rails
./bin/rails css:install:bootstrap
```

If you are using `cssbundling` or `jsbundling`, to fully *run* the app you need more than just `rails s`.

You need to also run `yarn build:css --watch`.

You will see that `css:install:bootstrap` added a file `Procfile.dev`. 

To run the app via `Procfile`:

```ruby
# install foreman to run the app via Procfile
gem install foreman
# run the app via Procfile
bin/dev
```

Here's how you can run your app on Heroku via a procfile: [Procfile: automatically run migrations on Heroku deploy]({% post_url 2021-08-10-heroku-procfile %})

P.S. With importmaps, the javascript tag looks like this:

```ruby
# app/views/application.html.erb
<%= javascript_importmap_tags %>
```

### Option 2: jsbundling + cssbundling

Prerequisites:
* node > 12
* yarn
* npm > 7

Check what you have installed:
* `node -v`
* `npm -v`

If you want to add bootstrap right when creating the app:

```ruby
rails new myapp2 -d=postgresql --css bootstrap
```

This will also install [jsbundling-rails](https://github.com/rails/jsbundling-rails) instead of Importmaps!

You will need to run the app via Procfile, just as above.

P.S. javascript tag with jsbundling looks like this:

```ruby
# app/views/application.html.erb
<%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
```

### 3. Fix javascript (tooltips, popups)

[Bootstrap tooltips docs](https://getbootstrap.com/docs/5.1/components/tooltips/)

[Bootstrap popovers docs](https://getbootstrap.com/docs/5.1/components/popovers/)

Actually, I've already created a post covering this: [Stimulus controllers to make Bootstrap popovers and tooltips work]({% post_url 2021-04-26-rails-bootstrap-5-yarn %})

Tooltips & Popups will not work out of the box. You will need to add some javascript to "switch them on". Create stimulus controllers:

```ruby
# console
rails g stimulus tooltip
rails g stimulus popover
```

```js
// app/javascript/controllers/tooltip_controller.rb
import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Connects to data-controller="tooltip"
export default class extends Controller {
  connect() {
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl)
    })
  }
}
```
```js
// app/javascript/controllers/popover_controller.rb
import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Connects to data-controller="popover"
export default class extends Controller {
  connect() {
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
      return new bootstrap.Popover(popoverTriggerEl)
    })

  }
}
```

Now you can initialize the stimulus controller **anywhere** on a page, where you want to use popover or tooltip:

```ruby
# anywhere in a view where you want tooltips and popovers to work
<div data-controller="tooltip"></div>
<div data-controller="popover"></div>
```

Or you can initialize these controllers all around your app:

```ruby
# app/views/application.html.erb
<body data-controller="popover tooltip">
```

Result:
![bootstrap-tooltip-and-popover.gif](/assets/images/bootstrap-tooltip-and-popover.gif)
