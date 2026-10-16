---
layout: post
title: "Rails World 2026: The Most Valuable Engineer Isn't Shipping Features (Robby Russell)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: XXjTdyhml0c
---

Robby Russell (Planet Argon, host of the On Rails podcast) gave a keynote about the unglamorous half of our work: tending to apps that already exist. If you maintain a mature Rails app, and most of us do, this one is about you, and about what happens when agents start reading your codebase.

## Key ideas

### Four answers to one question

Robby opened with a client: a mature Rails app, a team that doubled to 40-50 engineers, hundreds of integrations, and **four different patterns** for building those integrations. Each pattern had come from someone's blog post or experiment, and none of the old ones were ever removed.

The client asked for an architecture review. The real problem was that nobody felt authorized to say, in Robby's words, "we're doing it this way now". Newer engineers inherited all four, and everything already in the repo looked equally intentional.

### Makers and menders

Robby borrows Andrea Goulet's (Corgibytes) distinction: **makers** like building new things, **menders** like tending and improving what exists. Most professional work is mending. Tending the system is a big part of the job, and it doesn't take you away from it.

### The local workshop

Rails gives every app a shared starting point: you know where to trace a request, where migrations live, where jobs run. On top of that, every app builds its own **local workshop**: patterns, shortcuts, workarounds and exceptions.

Humans learn to compensate: we know which rake task is broken and who to ask before touching billing. The hotel-shower analogy: you figure out the knobs eventually, and the hotel thinks the shower works fine.

Agents don't build that memory. Every time the context is cleared, they search and infer again and burn tokens rediscovering what the team already knows. That makes the cost of friction visible. Robby suggests using it: if agents keep hitting a snag and burning money, you finally have an argument for fixing the thing that wasted human time for years.

Robby also pointed to Kent Beck's *Tidy First* (make the change easy, then make the easy change). Agents make tidying cheap, so one ticket can turn into several PRs, and now **review** is the bottleneck. The question is whether we are in our own version of *The Mythical Man-Month*.

### Be more like Q

In the James Bond films, Q runs R&D and makes sure the next mission needs less heroism. Engineering culture pushes everyone to be Bond. Robby argues the highest-leverage person is often Q, and you **don't need permission** to fix recurring friction, as long as the change is small, visible and reversible.

### Wonder, unpack, tinker, share

Robby's structure for curiosity:

1. **Wonder**: notice the moment something makes you pause, like a timeout set to exactly 47 seconds.
2. **Unpack**: do the archaeology. Read git history, measure production, find who added it. In Robby's informal poll of about 200 developers, roughly 8 in 10 said they would answer questions about code from a job they had left.
3. **Tinker**: write down what you expect, then make the smallest reversible change that gives you information.
4. **Share**: put what you learned back into the repo so the next person doesn't rediscover it.

A real example: middleware from 2018 that scrubs Unicode, with a comment saying to remove it once the legacy mobile app is retired. Instead of deleting it, they added logging. It fired 41 times in a week, all from a partner's crawler. The code stayed; the comment got fixed.

Another exercise: write a letter to your replacement, starting with *this is mostly a normal Rails app, except...* Then compare letters across the team.

### Three places to invest

- **Make the path obvious.** Encode the team's current way of doing things in a **generator**, so humans and agents start from the right place instead of copying one of 242 examples.
- **Make feedback fast and trustworthy.** Agents inherit your slow CI and flaky staging too.
- **Make mistakes cheap to reverse.** Feature flags, reversible migrations, preview environments, smaller deploys.

And across all three: **delete obsolete patterns**. Every abandoned approach still in the repo keeps teaching people, and agents, that it is a valid option.

## My takeaways

- Pick one abandoned pattern in your app, mark the current one clearly, and delete or label the old one.
- If your team keeps building the same kind of class, write a custom generator for it.
- Next time an agent goes in circles in your repo, write down where it got lost. That is the list of friction worth fixing.
- Write the letter to your replacement this week. It takes 20 minutes and shows you what isn't documented.

Watch the full talk: [The Most Valuable Engineer Isn't Shipping Features](https://www.youtube.com/watch?v=XXjTdyhml0c)
