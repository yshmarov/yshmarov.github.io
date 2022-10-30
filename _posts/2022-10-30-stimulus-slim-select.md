---
layout: post
title: "Slim Select with StimulusJS"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails turbo stimulusjs
thumbnail: /assets/thumbnails/stimulus-logo.png
---

**Goal**: Use [slim-select](https://slimselectjs.com/){:target="blank"} for searchable dropdowns and multiselect:

![slim-select-multiselect](/assets/images/slim-select-multiselect.gif)

When a select dropdown has too many values, it becomes uncomfortable to pick a value.

You would need to add **search** functionality to the dropdown.

The easies solution might be [HTML `<datalist>` tag](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/datalist){:target="blank"}:

![datalist with rails](/assets/images/datalist-select-example.gif)

However this approach still allows plain-text input, requires input validation and styling.

A better approach would be to use a javascript library. Some years ago my go-to library would be "selectize-js", however it reliest on jQuery. And in 2022 you don't want jQuery as a dependency in your app!

So, now I would prefer to use [tom-select]({% post_url 2021-09-23-select-or-create-with-tom-select %}){:target="blank"} or [slim-select](https://slimselectjs.com/){:target="blank"}. Neither of these libaries relies on jQuery!

### Prerequisites

Boilerplate app where we will add [slim-select](https://slimselectjs.com/){:target="blank"}:

```ruby
# yarn add slim-select
rails g model user email
rails g scaffold payment amount:integer user:references
rails db:migrate
bundle add faker
rails c
10.times { User.create(email: Faker::Internet.email) }
```

### Install [slim-select](https://slimselectjs.com/){:target="blank"}

```shell
# add the JS library with importmaps
./bin/importmap pin slim-select
# alternative - add the JS library with yarn
yarn add slim-select
# create stimulus controller that will initialize the JS
rails g stimulus slim
```

Initialize SlimSelect in the stimulus controller

```js
// app/javascript/controllers/slim_controller.js
import { Controller } from "@hotwired/stimulus"
// add the JS
import SlimSelect from 'slim-select'
// add the CSS
import 'slim-select/dist/slimselect.css'
// import "slim-select/dist/slimselect.min.css";

// Connects to data-controller="slim-select"
export default class extends Controller {
  static targets = ['field']
  connect() {
    new SlimSelect({
      select: this.fieldTarget,
      // closeOnSelect: false
    })
  }
}
```

Initialize the stimulus contorller on a rails field:

```ruby
# app/views/posts/_form.html.erb
<%= form.select :user_id, User.pluck(:email, :id), {include_blank: true}, {data: { controller: 'slim', slim_target: 'field' } } %>
```

**Result**: dropdown select with search using slim-select:

![slim-select](/assets/images/slim-select.gif)

### Multiselect

In this scenario, we will add multiple `Tags` to a `Post`.

Prerequisites:

```shell
rails g model tag name
rails g model post_tag post:references tag:references
10.times { Tag.create(name: Faker::Movie.title) }
```

```ruby
# app/models/post.rb
has_many :post_tags
has_many :tags, through: :post_tags
# app/models/tag.rb
has_many :post_tags
has_many :posts, through: :post_tags
# app/models/post_tag.rb
belongs_to :post
belongs_to :tag
```

Whitelist params:

```diff
# app/controllers/posts_controller.rb
-  params.require(:post).permit(:user_id)
+  params.require(:post).permit(:user_id, tag_ids: [])
```

Finally, just add the `multiple: true` in the html options of the select field:

```ruby
# app/views/posts/_form.html.erb
-<%= form.select :user_id, User.pluck(:email, :id), {include_blank: true}, {data: { controller: 'slim', slim_target: 'field' } } %>
+<%= form.select :tag_ids, Tag.all.pluck(:name, :id), {}, { multiple: true, data: { controller: 'slim', slim_target: 'field' } } %>
```

**Result**: dropdown **multi-**select with search using slim-select:

![slim-multiselect](/assets/images/slim-multiselect.gif)

### ⚠️ Troubleshooting

If the CSS for the multiselect does not render, you can try including it in a stylesheet:

```ruby
# app/views/layouts/application.html.erb
<%= stylesheet_link_tag "https://cdnjs.cloudflare.com/ajax/libs/slim-select/1.27.1/slimselect.min.css", "data-turbo-track": "reload" %>
```

or

```html
<!-- app/views/layouts/application.html.erb -->
<link href="https://cdnjs.cloudflare.com/ajax/libs/slim-select/1.27.1/slimselect.min.css" rel="stylesheet" crossorigin="" />
```

You can also try manually running `rails assets:precompile`, if you are not sure that the build happened. 🤷

That's it!

Resources:
* [rails `select_tag`](https://apidock.com/rails/ActionView/Helpers/FormTagHelper/select_tag)
* [rails `select`](https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/select)
