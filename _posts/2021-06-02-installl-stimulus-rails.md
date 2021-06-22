---
layout: post
title: "Install Stimulus on Ruby on Rails 6"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stimulus yarn webpacker
thumbnail: /assets/thumbnails/stimulus-logo.png
---

[Official Docs](https://stimulus.hotwire.dev/)

# 1. Install

console

```
yarn add stimulus 
mkdir app/javascript/controllers
touch app/javascript/controllers/index.js
```

#app/javascript/packs/application.js

```
import 'controllers'
```

#app/javascript/controllers/index.js

```
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("../controllers", true, /\.js$/)
application.load(definitionsFromContext(context))
```

# 2. See if it works

console
```
touch app/javascript/controllers/hello_controller.js
```

#app/javascript/controllers/hello_controller.js
```
import { Controller } from 'stimulus'; 
export default class extends Controller {
  connect() {
    console.log("hello from StimulusJS")
  }
}
```

in a view:

```
<div data-controller="hello">
  Anything
</div>
```

# 3. Log an action on a click

#app/javascript/controllers/hello_controller.js

```
  welcome() {
    console.log("click")
  }
```

in a view:

```
<div data-controller="hello">
  <div class="btn btn-primary" data-action="click->hello#welcome">log a click in console</div>
</div>
```

Now when you open the view, the `div` will call the `hello_controller` and add `hello from StimulusJS` in your browser console.
