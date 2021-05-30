---
layout: post
title: "Stimulus Rails - Count characters in input field"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stimulus
thumbnail: /assets/thumbnails/stimulus-logo.png
---

** Disclaimer: I'm still experimenting with Stimulus and this might not be the best way to do things **

Prerequisites:
* rails 6
* stimulus 2

Final solution demo:

![stimulus-count-characters-based-on-input.gif](/assets/images/stimulus-count-characters-based-on-input.gif)

HOWTO:

/app/javascript/controllers/countchar_controller.js

```
import { Controller } from "stimulus"
export default class extends Controller {
  static targets = [ "name", "counter" ]

  countCharacters(event) {
    let characters = this.nameTarget.value.length;
    this.counterTarget.innerText = characters;
  }
}
```

/app/views/posts/_form.html.erb

```
<div data-controller="countchar">
  <%= form.text_area :content, data: { countchar_target: 'name', action: 'keyup->countchar#countCharacters' } %>
  Characters: <span data-countchar-target='counter'><%= post.content.to_s.size %></span>
</div>
```
