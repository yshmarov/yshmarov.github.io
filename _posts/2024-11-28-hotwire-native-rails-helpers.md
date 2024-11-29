---
layout: post
title: Hotwire Native Rails Helpers
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/turbo.png
---

In previous blogposts of the Hotwire Native series I introduced helpers like `viewport_meta_tag`, `platform_identifier` & `bridge_form_with`.

### Pop navigation only on Native

If after opening a page you don't want to allow navigating to the last cached page, you will want to pop navigation with `turbo_action: 'replace'`, like it's done in [joemasilotti/daily-log/](https://github.com/joemasilotti/daily-log/blob/main/rails/app/views/sessions/new.html.erb#L8).

But you will likely want to apply this navigation pattern **only** on native.

Create this helper

```ruby
# app/helpers/hotwire_native_helper.rb
  def replace_if_native
    return 'replace' if turbo_native_app?

    'advance'
  end
```

And apply it:

```ruby
<%= form_for session_path(resource_name), data: { turbo_action: replace_if_native } do |form| %>
```

You will want to use `replace_if_native` on:
- Authentication pages
- Forms that open in a native modal

Learn more about [Turbo replace](https://turbo.hotwired.dev/handbook/drive#application-visits)

### Do not open internal links in in-app browser

Sometimes on the web you want to open an internal url in a new tab (`target: "_blank"`).

But if you have target blank in a Hotwire Native app, it will open your internal link in an in-app browser 🚩🚩🚩

=> I came up with this helper to override the link_to to remove target blank from internal links in Native apps

```ruby
# app/helpers/hotwire_native_helper.rb
def link_to(name = nil, options = nil, html_options = {}, &block)
    html_options[:target] = '' if turbo_native_app? && internal_url?(url_for(options))
    super(name, options, html_options, &block)
  end

  private

  def internal_url?(url)
    uri = URI.parse(url)
    return true if uri.path.present? && uri.host.blank?
    return true if url.include?(root_url)

    false
  end
```

More patterns to come, as I dive deeper into Hotwire Native!
