---
layout: post
title: "StimulusJS checkboxes. Select all. Deselect all"
author: Yaroslav Shmarov
tags: bulk-actions mass-params stimulusjs
thumbnail: /assets/thumbnails/checkboxes.png
youtube_id: Li4ag6xNKdk
---

With StimulusJS it's easy to add `Select all`, `Deselect all`:

![stimulus-select-all.gif](/assets/images/stimulus-select-all.gif)

```shell
# terminal
rails g stimulus checkbox-select-all
```

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox-select-parent"
export default class extends Controller {
  static targets = ["parent", "child"]
  connect() {
    // set all to false on page refresh
    this.childTargets.map(x => x.checked = false)
    this.parentTarget.checked = false
  }

  toggleChildren() {
    if (this.parentTarget.checked) {
      this.childTargets.map(x => x.checked = true)
      // this.childTargets.forEach((child) => {
      //   child.checked = true
      // })
    } else {
      this.childTargets.map(x => x.checked = false)
    }
  }

  toggleParent() {
    if (this.childTargets.map(x => x.checked).includes(false)) {
      this.parentTarget.checked = false
    } else {
      this.parentTarget.checked = true
    }
  }
}
```

In the HTML:
* initialize the stimulus controller `data-controller="checkbox-select-all"` around all the checkboxes
* "Select all" should have `data-checkbox-select-all-target="parent"` `data-action="change->checkbox-select-all#toggleChildren"`
* Each other checkbox should have `data-checkbox-select-all-target="child"` `data-action="change->checkbox-select-all#toggleParent"`
* BEWARE: each checkbox should have it's unique `id`, `name`, `value`

```html
<!-- html -->
<div data-controller="checkbox-select-all">
  <input type="checkbox" id="all" name="all" value="all" data-checkbox-select-all-target="parent" data-action="change->checkbox-select-all#toggleChildren">
  <label for="all"> Select all</label><br>
  <input type="checkbox" id="vehicle1" name="vehicle1" value="Bike" data-checkbox-select-all-target="child" data-action="change->checkbox-select-all#toggleParent">
  <label for="vehicle1"> I have a bike</label><br>
  <input type="checkbox" id="vehicle2" name="vehicle2" value="Car" data-checkbox-select-all-target="child" data-action="change->checkbox-select-all#toggleParent">
  <label for="vehicle2"> I have a car</label><br>
  <input type="checkbox" id="vehicle3" name="vehicle3" value="Boat" data-checkbox-select-all-target="child" data-action="change->checkbox-select-all#toggleParent">
  <label for="vehicle3"> I have a boat</label><br><br>
</div>
```

That will work.

Here's how you can do the same using rails `check_box_tag`:

```diff
+<div data-controller="checkbox-select-all">
+  <%= label_tag "select all" %>
+  <%= check_box_tag "select all", nil, nil, { data: { checkbox_select_all_target: "parent", action: "change->checkbox-select-all#toggleChildren" } } %>
<%= form_with url: bulk_update_users_path, method: :patch, id: :bulk_actions_form do |form| %>
  <%= form.submit "active" %>
  <%= form.submit "disabled" %>
<% end %>
<%= render partial: "user", collection: @users %>
+</div>
```

```diff
+<%= check_box_tag "user_ids[]", user.id, nil, { data: { checkbox_select_all_target: "child", action: "change->checkbox-select-all#toggleParent" }, multiple: true, form: :bulk_actions_form } %>
```

That's it!
