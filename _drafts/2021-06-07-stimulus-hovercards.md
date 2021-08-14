---
layout: post
title: "Stimulus Rails - Hovercards"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stimulus bootstrap5
thumbnail: /assets/thumbnails/stimulus-logo.png
---

** Disclaimer: I'm still experimenting with Stimulus and this might not be the best way to do things **

[Source: BoringRails](https://boringrails.com/articles/hovercards-stimulus/)

Final solution demo:

![stimulus-count-characters-based-on-input-css.gif](/assets/images/stimulus-count-characters-based-on-input-css.gif)

HOWTO:

app/javascript/controllers/hovercard_controller.js
```ruby
import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["card"];
  static values = { url: String };

  show() {
    if (this.hasCardTarget) {
      this.cardTarget.classList.remove("d-none");
    } else {
      fetch(this.urlValue)
        .then((r) => r.text())
        .then((html) => {
          const fragment = document
            .createRange()
            .createContextualFragment(html);

          this.element.appendChild(fragment);
        });
    }
  }

  hide() {
    if (this.hasCardTarget) {
      this.cardTarget.classList.add("d-none");
    }
  }

  disconnect() {
    if (this.hasCardTarget) {
      this.cardTarget.remove();
    }
  }
}
```

app/controllers/posts_controller.rb
```ruby
def hovercard
  @post = Post.find(params[:id])
  render layout: false
end
```

app/views/posts/hovercard.html.erb
```ruby
<div data-hovercard-target="card">
  <%= @post.title %>
  <%= @post.content %>
  <%= @post.created_at %>
</div> 
```

app/views/posts/index.html.erb
```ruby
<% @posts.each do |post| %>
  <div
    class="inline-block"
    data-controller="hovercard"
    data-hovercard-url-value="<%= hovercard_post_path(post) %>"
    data-action="mouseenter->hovercard#show mouseleave->hovercard#hide"
  >
    <%= link_to post.title, post, class: "branded-link" %>
  </div>
<% end %>
```

config/routes.rb
```ruby
resources :posts do
  member do
    get :hovercard
  end
end
```

Reuse: just add any other URL instead of `<%= hovercard_post_path(post) %>``

Next step - [Wrapping hte stimulus div into a rails helper](https://boringrails.com/tips/lightweight-components-with-helpers-stimulus)

Future readings:

* [https://github.com/skatkov/awesome-stimulusjs](https://github.com/skatkov/awesome-stimulusjs)
* [https://stimulus-components.netlify.app/docs/components/stimulus-read-more/](https://stimulus-components.netlify.app/docs/components/stimulus-read-more/)
