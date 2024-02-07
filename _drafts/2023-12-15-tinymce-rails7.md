---
layout: post
title: TinyMCE WYSIWYG editor with Rails
author: Yaroslav Shmarov
tags: rails pdf action-text wysiwyg
# thumbnail: /assets/thumbnails/docraptor.png
---


https://www.tiny.cloud/


```ruby
# Gemfile
gem "tinymce-rails"
```

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (!this.preview) tinymce.init({ selector: 'textarea.tinymce' })
  }

  disconnect() {
    if (!this.preview) tinymce.remove()
  }

  get preview() {
    return (
      document.documentElement.hasAttribute('data-turbo-preview')
    )
  }
}
```

<head>
<%= tinymce_assets %>
</head>

data: { controller: "tinymce"}



<%= tinymce %>

  <%= form.text_area :criterion, autofocus: true, class: "tinymce" %>

```ruby
  def tinymce_content_tag(content)
    content_tag :span, content, class: "no-tailwindcss-base"
  end
```

```yml
# config/tinymce.yml
menubar: insert view format table tools
height: 300
toolbar:
  - undo redo | formatselect | bold italic backcolor superscript subscript | alignleft aligncenter  +
    alignright alignjustify | bullist numlist outdent indent | removeformat | help'
plugins:
  - advlist
  - autolink
  - lists
  - link
  - image
  - charmap
  - preview
  - anchor
  - searchreplace
  - visualblocks
  - code
  - fullscreen
  - insertdatetime
  - media
  - table
  - code
  - help
  - wordcount
```