---
layout: post
title: "Rails World 2026: Ractors, Rails, and Robots: Automating the Path to Ractor-safety (Andrew Novoselac)"
author: Yaroslav Shmarov
tags: rails-world conference ruby ractors performance ai
thumbnail: /assets/thumbnails/youtube/MVKUx-B_wHs.jpg
image:
  path: /assets/images/youtube/MVKUx-B_wHs.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Ractors, Rails, and Robots: Automating the Path to Ractor-safety (Andrew Novoselac)"
youtube_id: MVKUx-B_wHs
---

Andrew Novoselac works on Shopify's Ruby and Rails infrastructure team. In a first-ever conference talk, Andrew explained how the team used an AI agent loop to map what it takes to make Rails **Ractor-safe**, and what has already landed upstream. The motivation is memory: today, more concurrency means more processes, and memory is expensive.

## Key ideas

### Why Ractors

- **Processes** run in parallel but don't share memory (copy-on-write pages diverge over time).
- **Threads** share memory but take turns holding the GVL.
- **Ractors** do both: each has its own lock, so they run Ruby in parallel inside one process and share loaded code.

Ractors have been experimental since Ruby 3.0, got big improvements in Ruby 4.0, and more are coming in 4.1. Shopify ran an experiment: they made part of Basecamp's open-source **Writebook** Ractor-safe and served it with **Kino**, an experimental Ractor web server. One process with nine Ractors used about **7x less memory** than a nine-process Puma cluster, at the cost of about **25% more latency** (more on why below). The details are in the [Ractors on Rails](https://railsatscale.com/2026-08-11-ractors-on-rails/) post on Rails at Scale.

### What "Ractor-safe" means

Anything shared between Ractors must be **deeply frozen**: the object, its instance variables, their instance variables, all the way down. Freezing a hash that contains a mutable array still raises `Ractor::IsolationError`. `Ractor.make_shareable` freezes the whole graph for you. The goal for Rails is to boot the app, make `Rails.application` shareable, then call it from request Ractors.

In practice you hit one error at a time: a `default_proc` in the initializers collection, a `Concurrent::Map` in Solid Cache, something in Action Cable. You can't see the finish line and you can't parallelize the work. Shopify also upstreamed patches so isolation errors now name the full chain of objects and instance variables that leads to the offender.

### The agent loop

They built a harness repo: vendored Ruby, Rack and Rails, a dummy app, skills for running tests and rebuilding Ruby, and a plan. Make the app shareable, then serve a 200, then keep adding features that break under Ractors and fix them, forever.

After about a week and about $2,000 of model credits, the app had 169 routes working inside Ractors, covering roughly 67% of the Rails codebase. Andrew then spent two weeks reading all of it, about 200 changed framework files. Roughly half was ready to upstream, some needed cleanup, and about 10% needed real design work. The agent also wrote 5,000-line methods and rescued isolation errors to get past problems. What mattered was the map of the problem it produced.

### Getting it upstream

The first upstream scope: `rails new`, scaffold some routes, make the app shareable, serve those routes from Ractors. Action Cable, jobs, Solid gems and development mode (lazy loading) are out for now. A nightly build generates a fresh app from Rails main and runs every scaffold route through a "check isolation" Ractor that logs warnings instead of raising, so they get the full error list at once. Over the summer the team shipped more than 100 PRs.

Patterns:

- **Freeze constants**. Enable RuboCop's `Style/MutableConstant` first; it removed about 30% of the errors.
- **Read-copy-update** for class attributes: dup, add, freeze, reassign, so the value is always shareable.
- **Dispatch back to the main Ractor** for things that can't move yet, like database connections (IO can't cross Ractor boundaries) and Nokogiri, using **ractor-dispatch**. That round trip through the main Ractor is the blocking point that explains the extra latency.

To try it:

```ruby
Rails.application.ractorize! # warns: experimental, subject to change
```

Shopify also published an app template with the right settings and a link to it in the talk. Read it before you run it.

## My takeaways

- Turn on `Style/MutableConstant` in your app and gems. It's useful even if you never run a Ractor.
- If you maintain a gem, start checking it with `Ractor.make_shareable`. Each isolation error you fix is a real contribution.
- Generate an app from Shopify's template, add one feature, and see what breaks. That's your first Rails PR.
- If you let an agent loose on a hard problem, budget for reading its output. Treat it as a map.

Watch the full talk: [Ractors, Rails, and Robots: Automating the Path to Ractor-safety](https://www.youtube.com/watch?v=MVKUx-B_wHs)
