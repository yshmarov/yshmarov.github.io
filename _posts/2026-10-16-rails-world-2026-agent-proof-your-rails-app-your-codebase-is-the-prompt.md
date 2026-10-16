---
layout: post
title: "Rails World 2026: Agent-Proof Your Rails App: Your Codebase Is the Prompt (Kinsey Durham Grace)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai testing
thumbnail: /assets/thumbnails/youtube/QMkZ2J24XGI.jpg
image:
  path: /assets/images/youtube/QMkZ2J24XGI.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Agent-Proof Your Rails App: Your Codebase Is the Prompt (Kinsey Durham Grace)"
youtube_id: QMkZ2J24XGI
---

Kinsey Durham Grace used to work on GitHub's Copilot coding agent platform team, watching agents work inside real codebases every day. Kinsey's claim: agents can write good Ruby, and when their PRs fail, the cause is usually the codebase and the missing verification around them. Every point is backed by a paper or benchmark.

## Key ideas

### Review harder doesn't scale

A survey Kinsey cited found 84% of developers use AI to write code, but only 29% trust it. Another study of 33,000+ agent-authored PRs found a conflict rate over 41% when two agents work on the same repo at once. Generation is cheap, verification is expensive, and promising to be more careful in review doesn't scale.

Agents break trust in three ways: they guess, they are confidently wrong, or they claim to have checked something they never opened. Kinsey found runs where the agent described a file in detail without ever reading it.

### Make the agent prove it

The question to ask after an agent run: what did it **prove** before saying it was done?

- A bug fix comes with a test that **fails before and passes after**. A test written after the fix just agrees with the fix.
- UI changes get run and checked locally.
- Performance changes come with before and after traces.

Rails already gives you most of this: `bin/rails test`, system tests that drive a real flow, fixtures for realistic data. Often the agent can't even boot the app: in one benchmark, the best model could set up a repo from scratch only 62% of the time, inventing config values and changing ports along the way.

Kinsey's fix is a **verification skill** per risky feature: a markdown file with four sections.

```markdown
## Boot
## Drive
## Evidence
- three specific, observable checks
## Cleanup
```

The evidence list is the contract: the agent can't claim it is done without producing it. Kinsey's examples: the post is published, it renders at its public URL, and the search index has a row for it.

### Climb the trust ladder

Kinsey describes five stages: watch every tool call, read every line of the diff, stop reading style because CI enforces it, read the **evidence** first and spot-check the code, and finally merge on green and review in the morning. Track clean merge rate, seven-day revert rate and review latency. If latency rises, you climbed too fast.

### Conventions beat cleverness

The Rails Foundation's **Agents on Rails** benchmark (21 atomic tasks against Writebook) had Opus 5 solving 92%, so small Rails tasks are mostly solved. The task that broke models was deleting a user's account properly, because the definition of properly lives in `dependent:` options across many files and in someone's head.

Agents explore your app with a shell and grep. So:

- **Metaprogramming hides methods.** A `define_method` loop that generates `published_at` means grep finds nothing, and the agent invents a definition or writes a duplicate.
- **Hand-rolled helpers cost twice.** `has_many` is already in the model's weights; your custom helper isn't.
- **Indirection is expensive.** A study that only moved code around (proxy chains, config split across YAML, initializers and the database) cut issue resolution from 66% to 49% and nearly tripled the files read.
- **Names matter.** Replacing meaningful identifiers with meaningless ones dropped a frontier model's code comprehension by 29 points.
- **Monoliths win.** In a modular-monolith vs microservices comparison, the monolith scored 97.7 against 70.7 with about 40% fewer tool calls.

For boundaries Kinsey suggests namespaces, Shopify's **packwerk** with violations as a CI gate, or engines with `isolate_namespace`. Each module owns its tables.

### Constraints beat instructions

A rule in `AGENTS.md` is a few tokens competing with 200,000 others. The same rule as a CI check costs no tokens and fails every time. The enforcement ladder, from weakest to strongest: a comment, `AGENTS.md`, a convention repeated across 40 files, a **generator**, a lint rule, a failing CI check, a type or interface boundary.

Kinsey recommended **pstack**, a plugin by Lauren ([poteto](https://github.com/poteto) on GitHub), for its `/how` and `/why` skills. The second digs through git history, issues and docs to recover the reasoning behind code. Write the answers down as feature maps, and automate their refresh: stale docs measurably hurt models.

## My takeaways

- Pick the three review comments you leave most often and move each one step up the ladder. One afternoon each.
- Write one verification skill for your riskiest flow, with a concrete evidence list.
- Grep your app for `define_method` and `method_missing` in models. Anything an agent can't find by name is a trap.
- Make sure `bin/setup` actually works in a fresh container. If the agent can't run your tests, it can't prove anything.

Watch the full talk: [Agent-Proof Your Rails App: Your Codebase Is the Prompt](https://www.youtube.com/watch?v=QMkZ2J24XGI)
