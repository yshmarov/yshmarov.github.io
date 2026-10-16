---
layout: post
title: "Rails World 2026: Opening keynote (DHH)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai
thumbnail: /assets/thumbnails/youtube/vDjW_dRyKXY.jpg
image:
  path: /assets/images/youtube/vDjW_dRyKXY.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Opening keynote (DHH)"
youtube_id: vDjW_dRyKXY
---

DHH opened Rails World 2026 in Austin with a keynote about agents, and almost nothing about new Rails APIs. If you want to know where the creator of Rails thinks our job is heading, and what 37signals is actually doing about it, this is the talk.

## Key ideas

### Photography as the analogy

The talk starts with portrait painting. DHH's great-great-grandfather, the Danish painter Laurits Tuxen, spent three years on a single royal family portrait. Then the Kodak Brownie made photography cheap, and painters had to find a different reason to exist. Decades later the phone camera made photos **too cheap to measure**.

DHH's point: technology moves in fits and starts, and agents are our Brownie moment. He dates the tipping point to **November 24, 2025** (the Opus 4.5 release), followed by a few months of disappointing models, then a big jump again in June.

### 37signals went pencils down

- At 37signals, writing code by hand is now an **exception**. When someone has to do it, that is treated as a bug in the process: fix the code, then fix the factory so the agent can do it next time.
- A show of hands in the room: only about five people still write meaningful amounts of code by hand every week.
- An earlier attempt failed. During Basecamp 5, designers vibe-coded features; each PR looked fine, but together, in DHH's words, they left the architecture "looking a little like a Swiss cheese". DHH now calls going back to manual review the wrong conclusion.
- His own numbers: roughly 30,000 lines of production Ruby per year for 21 years. In August 2026, about 150,000 lines in one month. Ruby went from over half of his output to about 3% this year.

### The next HEY: native clients and Rust

The new version of HEY will **not be a web app**. 37signals kicked off six native applications about a week before the talk. The argument: many apps were web apps only because native development was too expensive for a small team, and agents have removed that cost.

The backend is being turned into a mail server written in **Rust**. DHH says he finds Rust ugly to read, and does not care, because he never reads it. He treats the Rust code as a black box and judges it by the outputs: much lower CPU and memory, with 10 hosts mostly for redundancy.

### Where Rails still fits

The web stays the right platform for apps where people won't install anything, like Basecamp guests who drop in once to grab a file. DHH argues Rails' long-standing values map well onto agents:

- **Convention over configuration** means fewer tokens spent figuring out where things go.
- The **one-person framework** idea matches single developers doing much more with agents.
- Evil Martians run agent evals for the Rails Foundation against real reference apps. The first version saturated quickly, so it was made harder.

He also suggests revisiting abstractions: they existed partly to avoid repetition, and repetition is now nearly free, while abstractions become choke points when many agents edit the same codebase.

### Ship a CLI

The most concrete ask of the talk: **give your app a CLI**, so people can bring their own agent instead of using your built-in chatbot. The HEY CLI let his agent find a five-year-old email by concept when he remembered neither the sender, the company nor the year. His deadline for the audience: next Friday.

### Omarchy and tiny binaries

The rest is a tour of Omarchy, his Linux distribution: install time down to seconds, plus apps he built without reading the code (a calculator, a writing app, a video trimmer, and the presentation software for this keynote, at about half a megabyte). He also covered security worries briefly, pointing to the HotCell effort for Active Storage, and ended on a call for optimism.

## My takeaways

- **Build a CLI for your app.** Even a thin wrapper over your JSON endpoints lets agents use your product. I'd start with read-only commands.
- When you catch yourself fixing agent output by hand, ask what to change in the repo (docs, generators, tests) so the next run gets it right.
- Lean on Rails conventions harder. Every place your app deviates from the default costs tokens on every agent run.
- Treat the native-plus-Rust plan as one company's bet for an email client. For most CRUD apps with occasional visitors, DHH himself says Rails on the web still fits.

Watch the full talk: [Opening Keynote](https://www.youtube.com/watch?v=vDjW_dRyKXY)
