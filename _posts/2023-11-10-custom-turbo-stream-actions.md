---
layout: post
title: "Custom Turbo Stream Actions"
author: Yaroslav Shmarov
tags: rails hotwire turbo-streams modals
thumbnail: /assets/thumbnails/turbo.png
---

Hotwire Turbo Streams [let you](https://github.com/hotwired/turbo/pull/479) create custom turbo stream actions.

Example `actions` you could create:
- log text into console
- full-page redirect with a turbo_stream
- refresh a select turbo frame
- change css class of an element

### Before: How do we full-page redirect outside of a turbo_frame modal?

A common problem I have is being able to have a full-page redirect after submitting a form in a `turbo_frame` modal.

With modals, in some cases we would want a response to be:
- within the frame
- turbo streams
- full page refresh

```ruby
# app/controllers/*_controller.rb
  # request.variant = :turbo_frame
  def create
    respond_to do |format|
      format.turbo_stream do
        # impossible full-page redirect?
      end
    end
  end
```

Previously, to perform a full-page redirect in this scenario I would turbo_stream a link to the top of the page `<body>` and auto-click it.

Stimulus controller to autoclick an element:

```js
// app/javascript/controllers/autoclick_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  connect() {
    this.element.click()
  }
}
```

Next I would add a helper that:
- creates a basic HTML `<a href=>` link with a given url
- autoclicks this link when the link is available on a page
- `turbo_stream.append_all("body")` adds the generated link to the top of the document

```ruby
# app/helpers/turbo_stream_actions_helper.rb
module TurboStreamActionsHelper
  def turbo_stream_navigate(url)
    link = tag.a(
      nil,
      class: "hidden",
      href: url,
      data: {controller: "autoclick"}
    )

    turbo_stream.append_all("body") { link }
  end
end
```

So, a turbo response would add the link to a page and click it.

```diff
# app/controllers/*_controller.rb
  # request.variant = :turbo_frame
  def create
    respond_to do |format|
      format.turbo_stream do
+       render turbo_stream: helpers.turbo_stream_navigate(admin_assessment_form_path(@assessment_form))
      end
    end
  end
```

Smart workaround!

But a "correct" approach would be to use **custom Turbo Stream Actions**.

### Basic Custom Turbo Stream example: `console.log` 

You can add custom turbo stream actions directily in your `app/javascript/application.js`.

```js
// app/javascript/application.js
import { Turbo } from "@hotwired/turbo-rails"

// <turbo-stream action="console_log" message="<%= Time.zone.now"></turbo-stream>  
// turbo_stream.action(:console_log, message: "foo") // will this work?
Turbo.StreamActions.console_log = function() {
  const message = this.getAttribute("message")
  console.log(message)
}
```

Look [`here`](https://github.com/hotwired/turbo-rails/issues/441) if you have JS errors with importing StreamActions.

Now you can add a helper to use the usual Rails syntax for rendering turbo_streams:

```ruby
# rails generate helper TurboStreamActions

# app/helpers/turbo_stream_actions_helper.rb
module TurboStreamActionsHelper
  # render turbo_stream: turbo_stream.console_log("foobar")
  def console_log(message)
    turbo_stream_action_tag :console_log, message: message
  end 
end

# you need this line to tell the app that this file includes custom turbo stream action helpers
Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
```

Now you have 3 ways of invoking this turbo_stream:

```ruby
<turbo-stream action="console_log" message="<%= Time.zone.now"></turbo-stream>  
turbo_stream.action(:console_log, message: "foo") // will this work?
turbo_stream.console_log("foobar")
```

### **Redirect** with custom Turbo Stream Actions

Add the javascript redirect:

```js
// app/javascript/application.js

// enable Turbo.StreamActions
import { Turbo } from "@hotwired/turbo-rails"

// <turbo-stream action="redirect" target="/projects"><template></template></turbo-stream>
// turbo_stream.action(:redirect, projects_path)
Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target);
};
```

Use it in your controller:

```diff
  # request.variant = :turbo_frame
  def create
    respond_to do |format|
      format.turbo_stream do
-       render turbo_stream: helpers.turbo_stream_navigate(projects_path)
+       render turbo_stream: turbo_stream.action(:redirect, projects_path)
      end
    end
  end
```

And it will redirect! YAY!

### **Advanced** redirect with custom Turbo Stream Actions

In this case, we will pass the url not as a target but as a param. You could pass multiple params like this.

```js
// app/javascript/application.js
import { Turbo } from "@hotwired/turbo-rails"

// <turbo-stream action="redirect_advanced" url="<%= projects_path %>"></turbo-stream>
Turbo.StreamActions.redirect_advanced = function () {
  const url = this.getAttribute('url') || '/'
  // Turbo.visit(url, { frame: '_top', action: 'advance' })
  Turbo.visit(url)
}
```

Create a helper:

```ruby
# app/helpers/turbo_stream_actions_helper.rb
module TurboStreamActionsHelper
  # render turbo_stream: turbo_stream.redirect_advanced(projects_path)
  def redirect_advanced(url)
    turbo_stream_action_tag :redirect_advanced, url: url
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
```

Use it in your controller:

```diff
  # request.variant = :turbo_frame
  def create
    respond_to do |format|
      format.turbo_stream do
-       render turbo_stream: helpers.turbo_stream_navigate(projects_path)
-       render turbo_stream: turbo_stream.action(:redirect, projects_path)
+       render turbo_stream: turbo_stream.redirect_advanced(projects_path)
      end
    end
  end
```

Test the helper:

```ruby
# spec/helpers/turbo_stream_actions_helper_spec.rb
  it "returns a turbo-stream tag" do
    expect(helper.redirect("/projects")).to eq(
      "<turbo-stream url=\"/projects\" action=\"redirect_advanced\"><template></template></turbo-stream>"
    )
  end
```

That's it!

P.S. The gem [marcoroth/turbo_power-rails](https://github.com/marcoroth/turbo_power-rails) offers many custom turbo stream actions that you can import into your app. No need to reinvent the wheel!
