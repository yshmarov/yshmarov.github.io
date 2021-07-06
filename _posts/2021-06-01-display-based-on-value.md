---
layout: post
title: "Display or hide div based on field input (RoR + JS)"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails javascript
thumbnail: /assets/thumbnails/javascript.png
---

## Problem:

Display something only when a specific value is selected in a form

![unhide-based-on-input.gif](/assets/images/unhide-based-on-input.gif)

## Solution:

In this example - we display the field `quantity` only if the value in field `kids` is set to `yes`

application.scss

```
#hidden {   
  display: none; 
}
```

/app/views/posts/_form.html.erb

```
<%= form_with(model: booking) do |form| %>
  <%= form.label :kids %>
  <%= form.select :kids, [nil, "yes", "no"] %>
  
  <div id="hidden">
    <%= form.label "How many kids?" %>
    <%= form.text_field :quantity %>
  </div>
<% end %>
```

The above form generates HTML like this:

```
<form action="/bookings" accept-charset="UTF-8" method="post"><input type="hidden" name="authenticity_token" value="xxx">
  <div class="field">
    <label for="booking_title">Kids</label>
    <select name="booking[title]" id="booking_kids">
      <option selected="selected" value=""></option>
      <option value="yes">yes</option>
      <option value="no">no</option>
    </select>
  </div>

  <div id="hidden" style="display: none;">
    <div class="field">
      <label for="booking_quantity">quantity</label>
      <textarea name="post[quantity]" id="post_quantity"></textarea>
    </div>
  </div>
</form>
```

application.js:

* we grab the selector with ID `booking_kids` (autogenerated by the form id + form field)
* if `kids` value is set to `yes` - unhide `quantity` input

```
document.addEventListener("turbolinks:load", () => {
  const elem = document.getElementById('booking_kids');
  elem.addEventListener('change', () => {
    if (elem.value === 'yes') {
      document.getElementById("hidden").style.display = "initial"; 
    } else {
      document.getElementById("hidden").style.display = "none";
    }
  });
});
```

****

Bonus - more sophisticated select fields:

```
f.select :score, [['horrible', 1], ['poor', 2], ['mediocre', 3], ['good', 4], ['great', 5]]
f.collection_select :score_id, Score.all, :id, :name
```