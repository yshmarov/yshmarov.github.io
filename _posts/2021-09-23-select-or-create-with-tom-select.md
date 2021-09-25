---
layout: post
title: "Select or Create Tags with Tom-Select without jQuery (VanillaJS)"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails vanilla-js no-jquery stimulus
thumbnail: /assets/thumbnails/javascript.png
---

[Tom Select](https://tom-select.js.org/) is an improved FORK of SelectizeJS that I have been using for many years.
Most notably, it does not use jQuery.

Resources:
* [Tom Select Source Code](https://github.com/selectize/selectize.js)
* [Tom Select Official Website](https://tom-select.js.org/)

Special thanks to [secretpray](https://github.com/secretpray) for helping me with this one!

### Install

console
```
yarn add tom-select
```
app/javascript/stylesheets/application.scss
```
@import "tom-select/dist/css/tom-select.bootstrap5";
```
or
```
@import 'tom-select/dist/css/tom-select.css';
```
app/controllers/tags_controller.rb
```ruby
class TagsController < ApplicationController
  def create
    tag = Tag.new(tag_params)
    if tag.valid?
      tag.save
      render json: tag
    end
  end

  private

  def tag_params
    params.require(:tag).permit(:name)
  end
end
```
config/routes.rb
```ruby
  resources :tags, only: :create
```
app/views/posts/_form.html.erb
```ruby
  <div class="field">
    <%= form.label :tags %>
    <%= form.select :tag_ids, Tag.all.pluck(:name, :id), {}, { multiple: true, id: "select-tags" } %>
  </div>
```
app/views/layouts/application.html.erb
```ruby
    <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
```
app/javascript/packs/application.js
```ruby
require("utilities/tom_select")
```

### The only tricky thing - creating tags. We need to POST to tags#create and get back the json result

app/javascript/utilities/tom_select.js
```ruby
import 'tom-select'
import TomSelect from "tom-select"

document.addEventListener("turbolinks:load", () => {
  const selectInput = document.getElementById('select-tags')
  if (selectInput) {
    new TomSelect(selectInput, {
      plugins: {
        remove_button:{
          title:'Remove this item',
        }
      },
  		onItemAdd:function(){
  			this.setTextboxValue('');
  			this.refreshOptions();
  		},
      persist: false,
      create: function(input, callback) {
        const data = { name: input }
        const token = document.querySelector('meta[name="csrf-token"]').content
        fetch('/tags', {
          method: 'POST',
          headers:  {
            "X-CSRF-Token": token,
            "Content-Type": "application/json",
            "Accept": "application/json"
          },
          body: JSON.stringify(data)
        })
        .then((response) => {
          return response.json();
        })
        .then((data) => {
          callback({value: data.id, text: data.name })
        });
      },
      onDelete: function(values) {
        return confirm(values.length > 1 ? 'Are you sure you want to remove these ' + values.length + ' items?' : 'Are you sure you want to remove "' + values[0] + '"?');
      }
    })
  }
})
```

### ALTERNATIVE - async/await variant for `create`

app/javascript/utilities/tom_select.js
```ruby
      create: async function(input, callback) {
        const data = { name: input }
        const token = document.querySelector('meta[name="csrf-token"]').content
        let response = await fetch('/tags', {
          method: 'POST',
          headers:  {
            "X-CSRF-Token": token,
            "Content-Type": "application/json",
            "Accept": "application/json"
          },
          body: JSON.stringify(data)
        })
        let newTag = await response.json();

        return await callback({ value: newTag.id, text: newTag.name })
      },
```

### ALTERNATIVE - Stimulus variant

app/views/posts/_form.html.erb
```ruby
  <div class="field" data-controller="tom-select">
    <%= form.label :tags %>
    <%= form.select :tag_ids, Tag.all.pluck(:name, :id), {}, { multiple: true, id: "select-tags" } %>
  </div>
```

app/javascript/controllers/tom_select_controller.js

IN THIS CASE YOU CAN SKIP THE TURBOLINKS RELOAD LINE HERE!

`document.addEventListener("turbolinks:load", () => {``

app/javascript/controllers/tom_select_controller.js
```ruby
import { Controller } from "stimulus"

import 'tom-select'
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    console.log('tom_select_controller connected')

    ...

    const selectInput = document.getElementById('select-tags')
    if (selectInput) {
      new TomSelect(selectInput, {

    ...

  }
}
```

That's it!