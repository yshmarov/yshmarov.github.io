---
layout: post
title: Does Turbo 8 morphing make sence?
author: Yaroslav Shmarov
tags: rails hotwire turbo morphing
thumbnail: /assets/thumbnails/turbo.png
---

At Rails World I presented the [Hotwire Cookbook](https://superails.com/posts/rails-world-hotwire-cookbook-yaroslav-shmarov-common-uses-essential-patterns-best-practices) - a collection of UI behaviours that you can achieve **today** with Turbo Drive, Frames, Streams, and Stimulus.

In the meantime Jorge Manrubia [talked about **new/future** Hotwire/Turbo features](https://www.youtube.com/watch?v=hKKycPLN-sk). Mainly, about "Turbo Morphing". It was introduced in [this pull request](https://github.com/hotwired/turbo/pull/1019).

### What is **"morphing"**?

Morphing = refresh current page with preserving the scroll position; 

Full page refresh animation is skipped, because before the refresh happens, there is a "diff" of old VS new page, and only the diff gets updated.

### Try morphing (Turbo Drive)

Morphing will be released in Turbo 8, so currently the best way to try it together with all the other new features is to use the `main` git branch:

```ruby
# Gemfile
gem "turbo-rails", github: "hotwired/turbo-rails", branch: "main"
```

Enable turbo 8 morphing:

**Old**, default page refresh behaviour:

```ruby
# app/views/layouts/application.html.erb
<head>
  # <meta name="turbo-refresh-method" content="replace">
  # <meta name="turbo-refresh-scroll" content="reset">
  <%= turbo_refreshes_with method: :replace, scroll: :reset %>
  <%= yield :head %>
</head>
```

**New**, add morphing to your app by adding this:

```ruby
# app/views/layouts/application.html.erb
<head>
  # <meta name="turbo-refresh-method" content="morph">
  # <meta name="turbo-refresh-scroll" content="preserve">
  <%= turbo_refreshes_with method: :morph, scroll: :preserve %>
  <%= yield :head %>
</head>
```

Now, whenever you `redirect_to` current page, the scroll position will be preserved.

The easiest way to reproduce this behaviour is deleting a record from a list:
- without morphing, you would be redirected to the top of the page
- with morphing, you will keep scroll position, and the element will just disappear

This means you can use fewer TurboStreams in your app!

### Do not morph-refresh some elements

If an element should not be refreshed, add `data-turbo-permanent` attribute.

Previously, `data-turbo-permanent` required the presence of an [id] attribute. **Now it does not!**

For example: if you add `data-turbo-permanent` to this `<details>` dropdown, it will not **close** after a morph-refresh:

```diff
-<details>
+<details data-turbo-permanent>
  <summary>Details</summary>
  Something small enough to escape casual notice.
</details>
```

### New turbo stream action - `refresh`

* Morph-refresh for current user, only current tab? => `redirect_to`;
* Morph-refresh for all users on a page? => `TurboStreams`;

For this we have a new turbo stream `redirect` action has been introduced:

```html
<turbo-stream action="refresh"></turbo-stream>
```

Now you can trigger refreshes in a model, and **send updates to all clients/browser tabs**!

```ruby
# app/models/project.rb

# For this to work out of the box, consider using very RESTful (scaffold-default) conventions.
  broadcasts_refreshes

  # same as:
  after_create_commit  -> { broadcast_refresh_later_to(model_name.plural) }
  after_update_commit  -> { broadcast_refresh_later }
  after_destroy_commit -> { broadcast_refresh }
```

This would require having an open ActionCable/Websockets channel for this specific record:

```ruby
# app/views/projects/index.html.erb

<% @projects.each do |project| %>
  <%= turbo_stream_from project %>
  <%= render project %>
<% end %>
```

or directly within project partial

```ruby
# app/views/projects/_project.html.erb
<%= turbo_stream_from @project %>
```

I don't like invoking view-related logic from a model.

Instead, we can trigger refreshes from from the console:

```ruby
Turbo::StreamsChannel.broadcast_refresh_to @project
```

will refresh all pages that have the listener

```ruby
<%= turbo_stream_from @project %>
```

### Global refresh

Refresh current_page(s) **for all users** in the app 🤪

```ruby
# app/views/application.html.erb
Turbo::StreamsChannel.broadcast_refresh_to :global
<%= turbo_stream_from :global %>
```

Refresh all current page(s) for `current_user`:

```ruby
# app/views/application.html.erb
Turbo::StreamsChannel.broadcast_refresh_to current_user
<%= turbo_stream_from current_user %>
```

### Open questions:

* Can morphing replace turbo frames search?
* Would it correctly refresh based on each users' current query params?
* How would it work on a page with infinite pagination?
* Stimulus controller states can sometimes be out of sync after morph-refresh

Resources:
* [A happier happy path with turbo morphing](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/)
* [Turbo 8 in 8 minutes](https://fly.io/ruby-dispatch/turbo-8-in-8-minutes/)
* [Example PR using turbo morphing](https://github.com/basecamp/turbo-8-morphing-demo/pull/4)
