---
layout: post
title: "My StimulusJS templates"
author: Yaroslav Shmarov
tags: railsbytes rubidium generators templates scaffolds rails
thumbnail: /assets/thumbnails/script.png
---

To decrease copypasting, I've extracted the most common Stimulus controllers that I use in my apps into **TEMPLATES**.

To install the template (import the stimulus controller into your Rails app), just run the script.

1. `form-reset-on-connect`

Clears all inputs from a form on page refresh.

```ruby
rails_command "rails g stimulus form-reset-on-connect"
inject_into_file 'app/javascript/controllers/form_reset_on_connect_controller.js', after: "export default class extends Controller {" do
  <<-JAVASCRIPT
  connect() {
    this.element.reset()
  }
  JAVASCRIPT
end
```

2. `click-on-connect`

Clicks on an element when it appears on screen.

Useful for automatically clicking on links/buttons that appear after a turbo streams/frames responce.

```ruby
# run "bundle add devise"
# run "touch app/javascript/controllers/click_on_connect_controller.js"
rails_command "rails g stimulus click-on-connect"
inject_into_file 'app/javascript/controllers/click_on_connect_controller.js', after: "export default class extends Controller {" do
  <<-JAVASCRIPT
  static values = { open: Boolean }
  connect() {
    if (this.openValue) {
      this.element.click()
    }
  }
  JAVASCRIPT
end
```

3. `remote-click`

click a hidden link/button with a `data-action`

GET request to refresh a turbo_frame:

`= link_to "refresh results", request.url, data: { turbo_frame: :results, action: "change->remote-click#autoclick" }`

POST request to redirect, or to refresh a turbo_stream:

`= button_to "refresh results", request.url, data: { action: "change->remote-click#autoclick" }`

```ruby
rails_command "rails g stimulus remote-click"
inject_into_file 'app/javascript/controllers/remote_click_controller.js', after: "export default class extends Controller {" do
  <<-JAVASCRIPT
  static targets = ["clicker"]

  connect() {
    this.clickerTarget.hidden = true
  }

  autoclick() {
    this.clickerTarget.click()
  }
  JAVASCRIPT
end
```

3. `checkbox-select-all`

https://github.com/corsego/87-stimulus-select-all/blob/main/app/javascript/controllers/checkbox_select_all_controller.js

4. `dropdown`

5. `form-debounce`

delayed-submit

https://blog.corsego.com/turbo-hotwire-custom-search-without-page-refresh


```ruby
rails app:template LOCATION='https://railsbytes.com/script/x7ms44'
rails app:template LOCATION="{{ site.url }}/script-stimulus-click-on-connect.txt"
```
