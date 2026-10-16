---
layout: post
title: "Rails World 2026: Harness Engineering on Rails (Joël Quenneville)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai testing
thumbnail: /assets/thumbnails/youtube/L6-3a_rwLIg.jpg
image:
  path: /assets/images/youtube/L6-3a_rwLIg.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Harness Engineering on Rails (Joël Quenneville)"
youtube_id: L6-3a_rwLIg
---

Joël Quenneville (principal developer at thoughtbot, co-host of The Bike Shed) opened with a familiar story: an agent built a two-day feature in one hour, and the cleanup took the full two days. This talk is about raising the floor on agent-written Rails code without endless prompt tweaking.

## Key ideas

### An agent is a loop

A model on its own is a brain in a jar: text in, text out. The code around it, which reads files, writes files and calls the model, is the **harness**. Joël built a tiny one in Ruby for FizzBuzz, and the first answer had the classic bug: the divisible-by-15 branch never runs.

The fix is the same thing a developer does by hand: run the spec, read the failure, try again. Put that in a loop and the agent becomes **self-healing**. The first generation doesn't need to be perfect. Every commercial harness (Claude Code, Codex, Cursor) has a generic version of this loop at its core.

**Harness engineering** means leaning into that loop instead of prompting and praying.

### Keep style rules out of AGENTS.md

`AGENTS.md` is just text pasted in front of your prompt. It's probabilistic, and the more the context fills up, the more rules get ignored. Joël's approach: for each rule, ask how you'd enforce it without AI, then wire that tool into the loop.

Style already has a tool: RuboCop. Your `AGENTS.md` shrinks to directives:

```markdown
- After changing Ruby files, run RuboCop.
- Always create migrations with `bin/rails generate migration`.
```

That gets you most of the way. For 100%, use **hooks**, which vary by harness:

- A **stop hook** runs RuboCop when the agent tries to finish. If RuboCop fails, the agent isn't allowed to stop and has to fix the offenses.
- A **pre-write hook** calls a Ruby script that blocks new files in `db/migrate` and returns a reason: use the generator. The reason matters. A blocked agent still wants its migration, and if it doesn't know the right path it will hack around the block.

Be ambitious about what counts as lintable. Joël's example is a **custom cop** that catches unscoped finders in a multi-tenant app. If writing a cop feels intimidating, an LLM can draft one in minutes. Generators work the same way for structure: if every new controller should inherit from a certain base class or ship with a policy object, put that in a generator.

Moving judgment out of the LLM into deterministic tools made the whole system **smarter and more consistent**, even though less intelligence was involved.

### Steer from the middle

Some quality checks need judgment. Joël uses narrow **review skills**, run in sub-agents to reduce bias: a structural review, a method-by-method review and a polish pass. They live in Joël's public [JoelQ/skills](https://github.com/JoelQ/skills) repo.

Why is a skill better than the same advice in `AGENTS.md`? Up front, you ask the model to pick a correct program out of every possible program. After generation, you apply the heuristics backwards to one concrete program, and spotting violations there is much easier.

Joël maps this onto Birgitta Böckeler's grid from her harness engineering article on martinfowler.com: feedforward or feedback, computational or inferential.

- **Feedforward, computational**: generators, setup scripts, templates.
- **Feedback, computational**: RuboCop, reek, flog, security scanners, tests, logs, Playwright.
- **Feedback, inferential**: agentic review.
- **Feedforward, inferential**: prompts and `AGENTS.md`.

Move judgment out of the last quadrant, and keep `AGENTS.md` as a thin routing layer. One warning: Goodhart's law applies to agents too. Constrain them too tightly and they game the metric.

### Domain-specific scripts

On a document-import pipeline where only about 5% of documents made it through, an agent with full production access gave contradictory answers. Joël wrote a script that classifies every document by the stage where it dropped out of the funnel. Pointed at that, the agent got much better: stable definitions, a richer vocabulary (buckets, stages, exit points) and a natural starting point for each investigation. The same output fed a visualizer for humans, and rake tasks make this cheap.

### Fix the system after every correction

Drive improvements from real pain. Every time you correct an agent, ask how this could be the last time. Joël packaged these retrospective questions into a `retro` skill that reads a session's history and suggests automations. Matt Pocock's skills include a similar one.

## My takeaways

- Strip style rules out of `AGENTS.md` and replace them with one line: run RuboCop.
- Add a hook that blocks hand-written migration files and points to the generator.
- Write one custom cop for the mistake your agent keeps making, like a missing tenant scope.
- For messy data problems, write a rake task that classifies the data first, then hand that to the agent.

Watch the full talk: [Harness Engineering on Rails](https://www.youtube.com/watch?v=L6-3a_rwLIg)
