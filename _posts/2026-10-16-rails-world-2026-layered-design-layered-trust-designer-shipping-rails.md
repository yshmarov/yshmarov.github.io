---
layout: post
title: "Rails World 2026: How a Designer started shipping production Rails (Alicia Rojas and Arely Rivera)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai css
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: D1Y3tzhiAkw
---

Alicia Rojas (software engineer) and Arely Rivera (lead product designer), both at Telos Labs, told the story of a designer who at the start of the year couldn't run a Rails project, and then merged a 7,000-line PR to production. It is a good case study in what a small harness around front-end code can and can't catch.

## Key ideas

### The 7,000-line PR

The numbers: about 7,000 lines added, almost 2,000 deleted, 153 files. Alicia reviewed it, ran it locally, checked the critical flows end to end, and all four CI checks (security, linters, tests) were green. It shipped and broke in four ways.

Decomposed, the diff was less scary:

- **64%** was a dev-only component catalogue, never served to users.
- Only about **100 lines** of net-new production markup.
- The harness itself was tiny: a **46-line design tokens** file, one shared partial called from about **50 places**, and a **10-line contract** for the agent in a Claude markdown file (an `AGENTS.md` works the same).

Alicia wrote the ~600-line harness commit; Arely wrote 94% of the branch on top of it. The repo already had decent branch protection, trusted CI checks, and hook and permission settings that made it safe for a designer to work with agents.

### What escaped

1. **24 hard-coded hex colours** remained, violating the very rule the PR introduced. Two were in files the PR touched. A design review caught them.
2. A new page rendered a **duplicate canonical tag**. An SEO audit caught it.
3. **Every form label shrank**: one line in one form builder, token-compliant, CI green. Only a human UX audit noticed.
4. A **white navbar on a white page**, in one of five places, at a certain scroll position. Again, only a human saw it.

What the harness did catch: hard-coded hex values went from 119 to 24, with no invented components and no arbitrary fonts or spacing. The cost was one unplanned UX audit and four follow-up PRs. Their conclusion: an engineer's review asks different questions than QA, and an unenforced rule is only a suggestion.

### The onion design framework

Since the main reader of a design system is now often an agent, they organized theirs in five layers, each built on the one inside it:

1. **Core**: tokens only. Spacing, radius, elevation, colours.
2. **Primitives**: buttons, cards, inputs, carrying states and accessibility.
3. **Composed patterns**: blocks known to work, like a detail panel, so agents stop inventing new ones.
4. **Written rules**: when to use which pattern. Arely's analogy: primitives are wood and a knob, the pattern is a door, and the rule tells you when to use a wooden door or a sliding glass one.
5. **Screens**: the output, and the **evidence**. When a generated screen is wrong, trace the mistake back to the layer that caused it.

They tested three ways of writing the rules for agents: a strict schema, written prose, and linked annotations. Arely expected the linked version to win; it did worst. Schema and prose both did well, and they chose the schema as more cost-effective.

### Fidelity testing

A deliberately vague prompt: build a product page where someone can see, edit and delete products. The design system said products should be cards with images. Across **33 agent runs**, only 18% chose cards; the rest built perfectly reasonable tables. The cause was one ambiguous sentence in the rules, which agents read literally. After rewording it, 100% of runs produced cards. Removing the harness, with the same prompt, model and repo, produced visibly worse screens.

Arely's answer to whether designers are replaceable: the repeatable process, yes; the judgment, no. Someone still has to decide what is worth repeating.

## My takeaways

- Put your design tokens in one file and add a lint or CI check for hard-coded colours. Agents follow enforced rules far better than written ones.
- Extract the patterns you want reused into shared partials or ViewComponents, so agents compose instead of invent.
- Run the same vague prompt several times and treat every wrong result as a gap in your rules or components.
- Keep a human visual review for UI changes. Two of the four bugs here were invisible to CI.

Watch the full talk: [Layered Design, Layered Trust: How a Designer Started Shipping Production Rails](https://www.youtube.com/watch?v=D1Y3tzhiAkw)
