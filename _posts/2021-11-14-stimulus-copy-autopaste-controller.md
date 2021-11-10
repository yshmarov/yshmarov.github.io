---
layout: post
title: "StimulusJS autopaste controller"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stimulus
thumbnail: /assets/thumbnails/stimulus-logo.png
---

![stimulus copy from one field to another](/assets/images/copycat-controller.gif)

app/javascript/controllers/autopaste_controller.js
```js
import { Controller } from "@hotwired/stimulus"

  // EXAMPLE 1: display input from a field in HTML
  // <div class="field" data-controller="autopaste">
  //   <%= form.text_field :name, data: { autopaste_target: 'input', action: "keyup->autopaste#paste" } %>
  // <span data-autopaste-target="output"></span>

  // EXAMPLE 2: copy input from one field to other field
  // <div data-controller="autopaste">
  //   <%= form.text_field :name, data: { autopaste_target: 'input', action: "keyup->autopaste#paste" } %>
  //   <%= form.text_field :slug, data: { autopaste_target: 'output' } %>
  // </div>

export default class extends Controller {
  static targets = [ "input", "output" ]

  connect() {
    console.log('autopaste in da house')
  }

  paste () {
    // console.log(this.outputTarget.value)
    // console.log(this.inputTarget.value)
    this.outputTarget.value = this.inputTarget.value
  }

  paste_regex () {
    // Alternatively, you could add regex to the output field. Example:
    this.final = this.inputTarget.value.replace(/_/g, "-")
    this.final = this.final.replace(/ /g, "-")
    this.outputTarget.value = this.final
  }
}
```

* [More about JS regex](https://stackoverflow.com/questions/9311258/how-do-i-replace-special-characters-with-regex-in-javascript){:target="blank"}
