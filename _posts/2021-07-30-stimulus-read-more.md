---
layout: post
title: "Stimulus Read More - MY WAY!!!"
author: Yaroslav Shmarov
tags: stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

I did not find an easy Stimulus solution to this, so here is mine. Works. Easy. quite Light.

![stimulus-read-more](/assets/images/stimulus-read-more.gif)

## HOWTO:

read_more_controller.js
```js
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["shortText", "longText", "moreButton", "lessButton"]

  connect() {
    this.showLess()
  }

  showMore() {
    this.shortTextTarget.hidden = true
    this.moreButtonTarget.hidden = true
    this.longTextTarget.hidden = false
    this.lessButtonTarget.hidden = false
    console.log('show more')
  }

  showLess() {
    this.shortTextTarget.hidden = false
    this.moreButtonTarget.hidden = false
    this.longTextTarget.hidden = true
    this.lessButtonTarget.hidden = true
    console.log('show less')
  }
}
```

any view (html):
```ruby
<div data-controller="read-more">
  <div data-read-more-target="shortText">
    ABC
  </div>
  <div data-read-more-target="longText">
    ABCDEFG
  </div>
  <button role="button" tabindex=0 data-read-more-target="moreButton" data-action="read-more#showMore">
    Show more
  </button>
  <button role="button" tabindex=0 data-read-more-target="lessButton" data-action="read-more#showLess">
    Show less
  </button>
</div>
```

or any view (sexy haml):
```ruby
%div{ data: { controller: 'read-more'} }
  %div{ data: { target: 'read-more.shortText' } }
    ABC
  %div{ data: { target: 'read-more.longText' } }
    ABCDEFG
  %a{ data: { action: 'read-more#showMore', target: 'read-more.moreButton' } }
    Show more...
  %a{ data: { action: 'read-more#showLess', target: 'read-more.lessButton' } }
    Show less...
```

haml - with data
```ruby
%div{ data: { controller: 'read-more'} }
  %div{ data: { target: 'read-more.shortText' } }
    = truncate(post.body, length: 20, separator: ' ', omission: '...')
  %div{ data: { target: 'read-more.longText' } }
    = post.body
  %b
    %a.text-success{ role: 'button', tabindex: '0', data: { action: 'read-more#showMore', target: 'read-more.moreButton' } }
      more »
  %b
    %a.text-success{ role: 'button', tabindex: '0', data: { action: 'read-more#showLess', target: 'read-more.lessButton' } }
      less «
```
