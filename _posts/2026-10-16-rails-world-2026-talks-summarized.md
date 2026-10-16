---
layout: post
title: "Rails World 2026: every talk, summarized"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails
thumbnail: /assets/thumbnails/rails-logo.png
---

The Rails World 2026 recordings are out: 24 talks from Austin. I watched all of them and wrote a summary of each, with the key ideas and what I'd actually try afterwards.

The theme of the year was clear: **agents write a lot of the code now**, and the talks were about how a Rails codebase, a deploy pipeline and a team should adapt to that.

## Keynotes

- [Opening keynote (DHH)]({% post_url 2026-10-16-rails-world-2026-opening-keynote-rails-world-2026 %})
- [Ruby, Rails, and the future of programming (Matz, DHH & Jeremy Daer)]({% post_url 2026-10-16-rails-world-2026-ruby-rails-and-the-future-of-programming %})
- [The Most Valuable Engineer Isn't Shipping Features (Robby Russell)]({% post_url 2026-10-16-rails-world-2026-keynote-the-most-valuable-engineer-isn-t-shipping-features %})
- [Closing keynote (Aaron Patterson)]({% post_url 2026-10-16-rails-world-2026-closing-keynote-rails-world-2026 %})

## Coding with agents

- [Agent-Proof Your Rails App: Your Codebase Is the Prompt (Kinsey Durham Grace)]({% post_url 2026-10-16-rails-world-2026-agent-proof-your-rails-app-your-codebase-is-the-prompt %})
- [Harness Engineering on Rails (Joël Quenneville)]({% post_url 2026-10-16-rails-world-2026-harness-engineering-on-rails %})
- [Custom Rails Generators in RubyEvents (Rachael Wright-Munn)]({% post_url 2026-10-16-rails-world-2026-custom-rails-generators-in-rubyevents %})
- [How a Designer started shipping production Rails (Alicia Rojas & Arely Rivera)]({% post_url 2026-10-16-rails-world-2026-layered-design-layered-trust-designer-shipping-rails %})
- [From Prompt to Rails: An Online Rails App Generator (Paweł Strzałkowski)]({% post_url 2026-10-16-rails-world-2026-from-prompt-to-rails-an-online-rails-app-generator %})
- [Shipping is your heartbeat: Rails in the agentic era (Ryan Sherlock)]({% post_url 2026-10-16-rails-world-2026-shipping-is-your-heartbeat-rails-in-the-agentic-era %})

## AI features inside Rails apps

- [Agents on Rails: Building AI Pipelines in plain Ruby (Daniela Velasquez)]({% post_url 2026-10-16-rails-world-2026-agents-on-rails-building-ai-pipelines-in-plain-ruby %})
- [I Didn't Get MCP, So I Built My Way Through It (Enrique Mogollan)]({% post_url 2026-10-16-rails-world-2026-i-didn-t-get-mcp-so-i-built-my-way-through-it %})

## New in the framework

- [Active Search (Donal McBreen)]({% post_url 2026-10-16-rails-world-2026-active-search %})
- [Herb in Rails 8.2: Your ERB views, now HTML-aware (Marco Roth)]({% post_url 2026-10-16-rails-world-2026-herb-in-rails-8-2-your-erb-views-now-html-aware %})
- [Lexxy: a new text editor for Action Text (Jorge Manrubia)]({% post_url 2026-10-16-rails-world-2026-lexxy-a-new-text-editor-for-action-text %})
- [Durable orchestration on Rails: from continuation to workflow (Vladimir Dementyev)]({% post_url 2026-10-16-rails-world-2026-durable-orchestration-on-rails-from-continuation-to-workflow %})
- [A deep dive into Solid Cable (Nick Pezza)]({% post_url 2026-10-16-rails-world-2026-a-deep-dive-into-solid-cable %})
- [Practical Hotwire: Stimulus & Turbo on the Ground (Jeremy Smith)]({% post_url 2026-10-16-rails-world-2026-practical-hotwire-stimulus-turbo-on-the-ground %})

## Security, deploys and infrastructure

- [Hot Cell: Securing Active Storage in the age of AI (Mike Dalessio)]({% post_url 2026-10-16-rails-world-2026-hot-cell-securing-active-storage-in-the-age-of-ai %})
- [Kamal Deep Dive (Josef Strzibny)]({% post_url 2026-10-16-rails-world-2026-kamal-deep-dive %})
- [Distributing Rails applications with ONCE (Kevin McConnell)]({% post_url 2026-10-16-rails-world-2026-distributing-rails-applications-with-once %})
- [The RubyGems Compact Index: What Powers Every `bundle install` (Jenny Shen)]({% post_url 2026-10-16-rails-world-2026-the-rubygems-compact-index-what-powers-every-bundle-install %})
- [Sharding Is Hard: Let's Make It Easier! (Tess Griffin)]({% post_url 2026-10-16-rails-world-2026-sharding-is-hard-let-s-make-it-easier %})
- [Ractors, Rails, and Robots: Automating the Path to Ractor-safety (Andrew Novoselac)]({% post_url 2026-10-16-rails-world-2026-ractors-rails-and-robots-automating-ractor-safety %})

## If you only watch three

1. **Hot Cell** if your app accepts file uploads. Check your Rails version first.
2. **Harness Engineering on Rails** if agents write code in your app. It explains why rules belong in tests and linters, not only in `AGENTS.md`.
3. **Practical Hotwire**: twelve concrete ways Turbo and Stimulus bite, with fixes.

The lightning talks aren't on YouTube yet. I'll add them when they are.

All recordings are on the [Ruby on Rails YouTube channel](https://www.youtube.com/@railsofficial) and [RubyEvents](https://www.rubyevents.org/events/rails-world-2026).
