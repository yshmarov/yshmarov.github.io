---
layout: post
title: "Rails World 2026: Practical Hotwire: Stimulus and Turbo on the Ground (Jeremy Smith)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails hotwire turbo stimulus
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: ejOofhbYB3Q
---

Jeremy Smith framed his talk as a hot-sauce tasting: twelve common ways Hotwire burns you, three each for Stimulus, Turbo Drive, Turbo Frames and Turbo Streams. It builds the same instincts for Hotwire that most of us already have for models and controllers.

## Key ideas

### Stimulus

1. **Hand-written event listeners.** A dropdown that closes on outside click and Escape doesn't need `addEventListener` in `connect` and cleanup in `disconnect`. Stimulus actions handle that, including global ones like `click@window->dropdown#hide`.
2. **Feature-named controllers.** A `profile-bio` controller that counts characters, auto-sizes the textarea and autosaves can't be reused anywhere. Split it into general behaviors and compose them: `autosave` on the form, `autosize` on the textarea, `character-count` on a wrapper.
3. **Client-side work the server could do.** Validating and deduplicating a pasted list of emails in JavaScript means maintaining the same logic in JS and Ruby. Add a preview endpoint instead: the "check" button gets a `formaction` pointing at it, and the result renders into an empty div. Keep asking whether the server can and should do the work.

### Turbo Drive

4. **No teardown.** A third-party date picker set up in `connect` but never destroyed in `disconnect` stacks up a new dead copy every time you navigate back to the page.
5. **Dirty cache snapshots.** Drive snapshots the page when you leave, for back/forward and previews. Use `data-turbo-temporary` on flash messages, reset temporary UI (like a "confirm delete" state) in `disconnect`, and fall back to `turbo:before-cache` or opting out of the cache.
6. **Hover prefetch.** Turbo 8 prefetches a link after a short hover. Many hovers never turn into clicks, so you pay for server renders nobody sees, and GET requests with side effects (page view counters) fire anyway. Jeremy's default is to disable it on `<body>` and enable it only where the speed gain is worth the cost:

```html
<body data-turbo-prefetch="false">
  ...
  <a href="/products/1" data-turbo-prefetch="true">Bestseller</a>
```

For side effects, check the `X-Sec-Purpose: prefetch` request header on the server.

### Turbo Frames

7. **"Content missing".** A frame request whose response has no matching frame ID. Two causes: you broke the ID contract (a new branch or partial without the wrapping frame), or the response is legitimately something else, like a 404 for an archived record or a redirect to login after the session expired. Jeremy wraps the frame in a recovery Stimulus controller that listens for `turbo:frame-missing`, reports to the exception tracker, and shows a friendly message or follows the redirect.
8. **Lazy frames as N+1.** In his CI dashboard example, 20 runs each loading their own frame meant 21 requests and about 110 ms of total server time. Every request looked fast in the APM. The same page rendered with `includes` was one request, three queries and 30 ms.
9. **The inline-editing dead end.** Frames work while a request only changes one region. Once the business adds a setup checklist and a progress bar that also need to update, stop patching it and use Turbo Streams. Frames fix the target up front, while streams let each action choose what to update.

### Turbo Streams

10. **Ambiguous DOM IDs.** Streams fail silently when the target ID is wrong. If a task appears as a row *and* as a sidebar card, `dom_id(task)` can't address both. Name the specific representation, using the `dom_target` helper from Rails 8.1:

```erb
<div id="<%= dom_target(task, :row) %>">
<div id="<%= dom_target(task, :pin_card) %>">
```

11. **Broadcasts from model callbacks.** In his cafe ordering app, global streams leaked orders across cafes, and a bulk import fired one job and one broadcast per row. Scope stream names to the tenant (who), keep broadcast composition on the model (what), and let the operation decide when to deliver. Then a bulk import becomes a single message. `broadcasts_refreshes` is simpler, but every refresh triggers one request from each connected client.
12. **Personalized partials in broadcasts.** A partial that uses the current user or their time zone renders for whoever triggered the broadcast, and raises in a background job where there's no `Current` at all. Render what's true for everyone, then personalize in the browser: a Stimulus controller converts UTC timestamps to local time, and another compares a player key in a `<meta>` tag with the incoming one to swap a name for "you".

Code samples and a resource list are on [practicalhotwire.com](https://practicalhotwire.com).

## My takeaways

- Check your layout's `<body>`: decide on purpose whether hover prefetch is worth it for your app.
- Check lazy frames on index pages against total server time as well as page speed.
- Every Stimulus controller that creates something in `connect` should clean it up in `disconnect`.
- Move broadcasts out of `after_create_commit` callbacks for anything that can happen in bulk.

Watch the full talk: [Practical Hotwire: Stimulus & Turbo on the Ground](https://www.youtube.com/watch?v=ejOofhbYB3Q)
