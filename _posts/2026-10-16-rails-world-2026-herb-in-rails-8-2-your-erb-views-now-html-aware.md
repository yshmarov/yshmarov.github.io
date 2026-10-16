---
layout: post
title: "Rails World 2026: Herb in Rails 8.2: Your ERB views, now HTML-aware (Marco Roth)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails erb hotwire
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: REtfdqtW3PY
---

Marco Roth explained what changes when Rails 8.2 compiles your HTML+ERB templates with [Herb](https://herb-tools.dev), a toolchain that parses HTML and Ruby as one tree. The first half covered what ships in Rails. The second half launched **ReActionView v0.6**, which makes existing ERB views reactive with no JavaScript framework. Every Rails developer writes ERB, so both halves are worth your time.

## Key ideas

### What ships in Rails 8.2

Herb already gives you a linter, a formatter, a language server and dev tools. Rails 8.2 (not released yet at the time of writing) adopts its **engine** for rendering. With `config.load_defaults 8.2`, HTML-format templates compile through Herb. Everything else (text emails, JSON, other formats) keeps using Erubi.

```ruby
# config/initializers/new_framework_defaults_8_2.rb
Rails.application.config.action_view.erb_implementation = :herb
```

Herb reports structural problems, such as an unclosed tag, at compile time with the template location. Valid templates render the same output as with Erubi. To check whether your app is ready:

```bash
bin/rails herb:check
```

It lists every template that fails to compile through Herb and exits non-zero, so you can run it in CI. If you need to wait, set `erb_implementation = :erubi`.

### Herb v0.11

Released alongside the talk, with 30 contributors. Highlights Marco picked:

- **LSP:** find references for partials (useful when you or an agent refactor views), workspace and monorepo support, and an "Extract to Partial" code action.
- **Runtime instrumentation:** every ERB tag is instrumented and matched with Active Support notifications. You can see which tag fired which SQL query, with diagnostics and lint warnings shown in the browser and a reworked error overlay.
- **Roughly 50 new lint rules**, many specific to Action View (prefer `form_with`, prefer collection rendering, no unused strict locals, and so on).

### ReActionView: reactive ERB

Marco's argument: Rails 7 simplified the frontend with Hotwire, Rails 8 simplified infrastructure with the Solid trifecta, but the view layer hasn't kept up for more interactive UIs. Since the compiler now understands your templates, it can make them reactive.

How it works: Herb splits each ERB output into an addressable **slot** (marked with HTML comments in the rendered page). Server and client both know the template's slot schema. On later requests the server only sends new slot values, and the client patches them in place without a full page reload or a morph. Updates can come over HTTP, Action Cable, server-sent events, or from the client itself.

For UI-only state (show/hide, toggles), you declare state in the template and change it with HTML attributes, without a Stimulus controller or a server round trip:

```erb
<%# herb:slots server %>
<%# herb:state (composing: false) %>

<button data-herb-toggle="composing">New message</button>

<% if composing %>
  <%= render "messages/form" %>
<% end %>
```

The compiler understands a subset of Ruby that's common in views, so simple expressions run in the browser with no Ruby-to-JS transpiler and no WebAssembly. Anything it can't evaluate (like a database query that depends on a search-term state) falls back to a server request that returns only the affected slots. An input whose value is a single state expression gets two-way binding.

There are also built-in components: `<Async>` renders a fallback skeleton first and fetches the slow part afterwards, and `<Lazy>` waits until the element is near the viewport. Marco demoed a music library in about 100 lines of ERB with no JavaScript, and a chat app with optimistic UI that rolls back failed requests from a log of state changes. For anything more advanced there's a low-level JavaScript API.

```bash
bundle add reactionview
bin/rails generate reactionview:install
```

It works on Rails 7.0+ (on Rails before 8.2 it brings the Herb engine itself). Docs are at [reactionview.dev](https://reactionview.dev).

### What's next

Scoped `<style>` tags per partial, powered by a new `lightningcss-ruby` gem; scoped scripts and bundling via `oxc-ruby`, which handles TypeScript and JSX with no Node, compatible with importmaps; and a way for gems to ship components with both a server and a client part.

## My takeaways

- Run `bin/rails herb:check` on your app now, before upgrading to 8.2. Fixing malformed HTML is worth it regardless.
- Install the Herb linter and language server in your editor. The partial-references feature alone makes refactoring views easier.
- Try ReActionView on one interactive screen where you'd otherwise write a small Stimulus controller, and send Marco feedback. He asked for real adopters.

Watch the full talk: [Herb in Rails 8.2: Your ERB views, now HTML-aware](https://www.youtube.com/watch?v=REtfdqtW3PY)
