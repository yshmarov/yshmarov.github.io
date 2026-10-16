---
layout: post
title: "Rails World 2026: Shipping is your heartbeat: Rails in the agentic era (Ryan Sherlock)"
author: Yaroslav Shmarov
tags: rails-world conference ci testing ai
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: EBJF55TyCVY
---

Ryan Sherlock leads infrastructure and core technologies at Fin (formerly Intercom, recently acquired by Salesforce). Their Rails monolith is 15 years old, about five million lines, runs on Rails edge, and ships around 200 times a day, with first production traffic about five minutes after merge. The talk is a tour of the machinery that makes that safe, now that agents write most of the code.

## Key ideas

The loop is simple: every change is a hypothesis, production gives you evidence, the next change uses it. The job of the platform team is to make that loop fast. Stability is not an excuse to go slow. Instead: **small changes, trustworthy evidence, fast recovery**.

### Test selection with Rotoscope

The suite grew to about 225,000 specs (they doubled it in a year, partly thanks to agents). Run serially that's roughly 60 hours. A typical PR touches four files.

They use Shopify's **Rotoscope** gem, a fast logger of method invocations. Every morning they run the whole suite through it to build a map of which source files each spec touches, and patch that map every 30 minutes. Change `conversation.rb`, run only the specs that touched it. Safety nets:

- a set of specs that always run (core workflows, security);
- directories where any change triggers the full suite;
- specs added since the last map refresh always run;
- an empty commit escape hatch for a full run;
- a full run before production anyway.

The result: test time went from about 7.5 minutes to under 3, using about **5% of the compute**. Fewer specs run also means fewer flaky failures. Specs are split across up to 1,400 workers by recorded duration, not by file.

### Boot and build

- **Bootsnap** cache precompiled into the CI image, so runners start warm.
- `rails db:schema:cache:dump` uploaded to S3, so hundreds of booting processes don't hammer the database with column lookups (years ago this caused a mini outage on every deploy).
- An SQL annotation helper that materialized the full `caller` stack was rewritten as a lazy, allocation-free walk. That one change cut **about 20% of CI time**.
- Don't redo work when inputs haven't changed: skip `bundle install` unless the Gemfile or lockfile changed, and reuse the schema cache until migrations change.
- They went from six build artifacts (two CPU architectures times three regions) to one, stopped shipping `spec/` and `node_modules` to production, and found an old Tailwind CSS change that had disabled the asset cache in production for five years. Build time went from 4.5 minutes to 53 seconds.

### Deploy and rollback

Artifacts go to S3, and every box is told to download the new version and rotate processes, keeping the previous four versions on disk. **Heartbeat metrics** watch business outcomes as well as servers: comments flowing between customers and their users, teammates moving through the inbox. A bad query in August triggered an alarm after two minutes, which opened an incident, paged people and **rolled back automatically**, with no human and no LLM involved. Small changes are what make rollback always safe.

### Agent review and auto-approval

A large share of their PRs are now agent-driven, and their measured velocity is up 3-4x in 16 months. That made review the bottleneck. AI reviews used to be long, flattering comments nobody read. Their internal review agent grades five stages: problem statement, intent (does the code do only what the PR says?), safety rules per repository, logic, and codebase practices. They seeded those practices by mining years of review comments from their best reviewers.

Then they let it approve. They built a ground-truth set of about 1,000 past PRs that caused incidents, iterated until the bot caught them, and backtest every prompt or model change against it. It only auto-approves in some repos, under a 150-line limit, and never approves agent-authored code by itself. Results: median PR-to-merge went from 160 to 36 minutes, 40% of PRs are auto-approved, the revert rate for those is 0.5%, and median PR size dropped to 68 lines.

## My takeaways

- Dump your schema cache in production and precompile Bootsnap in your Docker image. Both are cheap wins.
- Profile your CI. Look for hot helpers that call `caller` and for static work you redo on every run.
- Look at what goes into your deploy image. Your specs probably don't belong there.
- Make rollback fast and boring before you try to make deploys faster.

Watch the full talk: [Shipping is your heartbeat: Rails in the agentic era](https://www.youtube.com/watch?v=EBJF55TyCVY)
