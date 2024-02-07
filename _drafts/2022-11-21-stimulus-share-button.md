---
layout: post
title: "StimulusJS social SHARE button"
author: Yaroslav Shmarov
tags: stimulusjs social-share
thumbnail: /assets/thumbnails/stimulus-logo.png
---

```shell
rails g stimulus share
```

```js
// app/javascript/controllers/share_controller.js
import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="share"
export default class extends Controller {
  static targets = ["result", "title", "body"];

  connect() {
    console.log("Connected to the share controller");
    console.log(this.data.get("urlValue"));
    console.log(this.resultTarget);
  }
  async share(e) {
    e.preventDefault();

    const shareData = {
      url: this.data.get("urlValue"),
      body: this.bodyTarget.textContent, // text
      title: this.titleTarget.textContent,
      // files: this.fileTarget
    };
    try {
      await navigator.share(shareData);
      this.resultTarget.textContent = "MDN shared successfully";
    } catch (err) {
      this.resultTarget.textContent = `Error: ${err}`;
    }
  }
}
```

```html
<div id="<%= dom_id post %>" 
  data-controller="share" 
  data-share-url-value="<%= post_url(post) %>">
  <p>
    <strong>Title:</strong>
    <%= content_tag(:p, post.title, data: {
      share_target: "title"
    }) %>
  </p>
  <p>
    <strong>Body:</strong>
    <%= content_tag(:div, post.body, data: {
      share_target: "body"
    }) %>
  </p>
  <%= button_to "Share", "", data: {
    action: "click->share#share"
  } %>
  <%= content_tag(:p, "", class:"result", data: {
    share_target: "result"
  }) %>
</div>
```

Share
https://www.youtube.com/watch?v=S5E838sDxAk
Share link:
https://developer.mozilla.org/en-US/docs/Web/API/Navigator/share

https://github.com/Deanout/share_button
