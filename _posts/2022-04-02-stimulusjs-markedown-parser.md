---
layout: post
title: "Integrate MarkedJS Markdown Parser into a Rails app"
author: Yaroslav Shmarov
tags: markdown marked stimulusjs
thumbnail: /assets/thumbnails/markdown.png
---

[Marked](https://www.npmjs.com/package/marked) is a js package to parse markdown.

You can use it as a lightweight approach to display markdown in your app.

### 1. Parse to markdown while typing

![markedjs - input form with markdown output](/assets/images/marked-js-input-output.gif)

```sh
# Terminal
bin/rails g scaffold messages content:text
bin/rails g stimulus markdown
bin/rails g stimulus markdown-display
# using importmaps
bin/importmap pin marked
# or using jsbundling
yarn add marked
```

```ruby
# views/messages/_form.html.erb
<div data-controller="markdown">
  <%= form.text_area :content, rows: 15, data: { action: "keyup->markdown#change", markdown_target: "input" } %>
  <div data-markdown-target="output">
</div>
```

```js
// javascript/controllers/markdown_controller.js
import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

// Connects to data-controller="markdown"
export default class extends Controller {
  static targets = ["input", "output"]

  connect() {
    this.parse()
  }

  change() {
    this.parse()
  }

  parse() {
    this.outputTarget.innerHTML = marked.parse(this.inputTarget.value)
  }
}
```

### 2. Parse `html` to `markdown` on page load

![markedjs - parse html to markdown on page load](/assets/images/marked-js-parse-on-connect.gif)

```ruby
# views/messages/_message.html.erb
<%= content_tag :div, message.content, data: { controller: "markdown-display" } %>
```

```js
# javascript/controllers/markdown_display_controller.js
import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

// Connects to data-controller="markdown-display"
export default class extends Controller {
  connect() {
    this.element.innerHTML = marked.parse(this.element.innerHTML)
  }
}
```

****

Full credit to [source](https://www.driftingruby.com/episodes/markdown-parser). I've added the solution on my blog primarily in case I lose access to the authors content.

****

🤔 However at some point you might want to have more control of the rendered markdown. 

Than you will want to use:
1. [gem redcarpet]({% post_url 2021-06-10-markdown %}){:target="blank"} to parse markdown
2. [gem rouge]({% post_url 2021-07-06-markdown-styling-with-rouge %}){:target="blank"} to style programming language syntax
3. [live previews with hotwire]({% post_url 2022-04-01-live-form-validation-errors-markdown-previews %}){:target="blank"} to render the output as you type
4. [StimulusJS textarea autogrow]({% post_url 2022-03-31-stimulus-textarea-autogrow %}){:target="blank"} to grow your input area as you type
