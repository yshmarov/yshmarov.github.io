---
layout: post
title: Hotwire Native Bridge Form Component with Rails
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/turbo.png
---

The demo app offers a Bridge Form example.

Basically it hides the web "submit" button, and shows a native one in the top-right corner of your mobile screen.

The source files for the Bridge form:
- [iOS/FormComponent.swift](https://github.com/hotwired/hotwire-native-ios/blob/main/Demo/Bridge/FormComponent.swift)
- [StimulusJS form_controller.js](https://github.com/hotwired/hotwire-native-demo/blob/main/public/javascript/controllers/bridge/form_controller.js)
- [HTML example of using this form](https://github.com/hotwired/hotwire-native-demo/blob/main/views/bridge-form.ejs)

Applying this stimulus controller to a Rails form would look like this:

```ruby
<%= form_with(model: User.new,
              data: { controller: "bridge--form",
                      action: "turbo:submit-start->bridge--form#submitStart turbo:submit-end->bridge--form#submitEnd" },
              class: "contents") do |form| %>
  <%= form.text_field :first_name %>
  <%= form.text_field :last_name_name %>
  <%= form.submit data: { "bridge--form-target": "submit" }, class: "bg-blue-600" %>
<% end >
```

To make it more reusable, you can abstract the application of these data attributes to a form helper:

```ruby
# rails/app/helpers/form_helper.rb
# source: https://github.com/joemasilotti/daily-log/blob/main/rails/app/helpers/form_helper.rb
module FormHelper
  class BridgeFormBuilder < ActionView::Helpers::FormBuilder
    def submit(value = nil, options = {})
      options[:data] ||= {}
      options["data-bridge--form-target"] = "submit"
      options[:class] = [options[:class], "turbo-native:hidden"].compact
      super(value, options)
    end
  end

  def bridge_form_with(*, **options, &block)
    options[:html] ||= {}
    options[:html][:data] ||= {}
    options[:html][:data] = options[:html][:data].merge(bridge_form_data)

    options[:builder] = BridgeFormBuilder

    form_with(*, **options, &block)
  end

  private

  def bridge_form_data
    {
      controller: "bridge--form",
      action: "turbo:submit-start->bridge--form#submitStart turbo:submit-end->bridge--form#submitEnd"
    }
  end
end
```

Now when you want to have a native "submit" button, you can use `bridge_form_with` instead of `form_with`:

```ruby
<%= bridge_form_with(model: User.new, class: "contents") do |form| %>
  <%= form.text_field :first_name %>
  <%= form.text_field :last_name_name %>
  <%= form.submit "Save", class: "bg-blue-600" %>
<% end %>
```

In some cases you will want to add `, html: {"data-turbo-action": "replace"}` to your form. It can make the page refresh/redirect feel better after saving the data.

**⚠️ TROUBLESHOOTING**

`form.submit` might or might not need a title to function.

```ruby
form.submit "Save"
form.submit
```

[Subscribe to SupeRails.com](https://superails.com/pricing) for more Hotwire Native content!

That's it for now!
