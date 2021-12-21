---
layout: post
title: "TIL: HTML tags I did not know about"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails today-i-learned html
thumbnail: /assets/thumbnails/html.png
---

HTML has evolved a lot over the years and has added a lot of "RICH" elements.

Here are some cool HTML elements that I've just recently learned about:

### 1. `<datalist>`

`<datalist>` - lightweight autocomplete

[MDN datalist docs](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/datalist){:target="blank"}

![html datalist](/assets/images/1-html-datalist.gif)

**Example of using `<datalist>` in a rails form:**

* add a collection for the datalist:

```ruby
# app/models/post.rb
  DEFAULT_COUNTRIES = ["European Union", "United States", "China", "Ukraine", "United Kingdom"].freeze
```

* add a datalist collection with an ID (`'default-countries'`)
* add `list` attribute to a text field, pointing to the datalist collection with an ID (`'default-countries'`)

```ruby
# app/views/posts/_form.html.erb
<%= form.text_field :icon, list: 'default-countries', placeholder: "select or add your own" %>
  <datalist id="default-countries">
    <% Post::DEFAULT_COUNTRIES.each do |x| %>
      <option value="<%= x %>"></option>
    <% end %>
  </datalist>
```

* same as above, different syntax:

```ruby
# app/views/posts/_form.html.erb
<%= form.text_field :icon, list: "default-countries", placeholder: "select or add your own" %>
  <datalist id="default-countries">
    <%= options_for_select(Post::DEFAULT_COUNTRIES) %>
  </datalist>
```

![datalist with rails](/assets/images/datalist-select-example.gif)

### 2. `<details>`

`<details>` - dropdowns without any extra CSS/JS!

[MDN details docs](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details){:target="blank"}

![html details](/assets/images/2-html-details.gif)

### 3. `<meter>`

`<meter>` - progress bar that changes color based on fill

[MDN meter docs](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meter){:target="blank"}

![html meter](/assets/images/3-html-meter.gif)

### 4. `<progress>`

`<progress>` - progress bar with ZERO extra CSS

[MDN progress docs](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/progress){:target="blank"}

![html progress](/assets/images/4-html-progress.gif)

****

[My initial tweet about this](https://twitter.com/yarotheslav/status/1443190441973850112){:target="blank"}