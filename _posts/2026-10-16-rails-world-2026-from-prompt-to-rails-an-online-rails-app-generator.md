---
layout: post
title: "Rails World 2026: From Prompt to Rails: An Online Rails App Generator (Paweł Strzałkowski)"
author: Yaroslav Shmarov
tags: rails-world conference ai hotwire docker
thumbnail: /assets/thumbnails/youtube/0_ZLKWlc7FY.jpg
image:
  path: /assets/images/youtube/0_ZLKWlc7FY.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: From Prompt to Rails: An Online Rails App Generator (Paweł Strzałkowski)"
youtube_id: 0_ZLKWlc7FY
---

Paweł Strzałkowski, CTO of the Warsaw Ruby agency Visuality, built **Hifumi**: a Lovable/Bolt-style generator where you describe an app in a prompt box and get a Rails app instead of a JavaScript one. It's open source and hosted at [hifumi.dev](https://hifumi.dev). Paweł's argument: whatever stack the prompt box produces is the stack the next non-technical founder ends up on, so Rails should have one too.

## Key ideas

### The flow

Idea, then follow-up questions, then a plan, then build, preview, refine, and finally export to your own GitHub.

The chat (built with **RubyLLM**) asks clarifying questions first, the way you would with a client. One of them is whether to include sample data, because an empty app looks bad and a seeded one shines. You can pick different models for different subtasks. The hosted version asks for your own OpenRouter key; Paweł is not paying for your tokens.

### Plans are split into revisions

Hifumi never sends the raw user prompt to a coding agent. It first writes an **implementation plan** split into phases, which Hifumi calls **revisions**. Each revision has a one-line goal and a scope of work that is really a page-long prompt for the agent. A prompt for a blog with posts and comments became a five-revision plan, starting with the models and moving through layout, seed data and end-to-end tests.

Plan rules that mattered:

- Always start from a pre-made `rails new` skeleton, never from scratch.
- Decide the front-end template, colors and fonts up front.
- **Put the main feature at the root path.** Otherwise the agent may build a great app and you open it to a blank page.
- Plans that modify an existing app need different wording, so the agent changes code instead of rebuilding everything.

### Each revision is a Roast workflow

Revisions run through **Roast**, Shopify's open-source Ruby DSL for workflows that mix deterministic steps with LLM steps. Paweł kept RubyLLM for chat and Roast for the build pipeline on purpose, to keep the two decoupled.

Per revision:

1. Build a prompt from the revision's scope, the project docs written so far, a snapshot of the workspace, and rules such as following the Rails way and writing tests.
2. Run **Claude Code** with `--dangerously-skip-permissions`, since nobody is there to approve tool calls.
3. Verify: `bundle` works, every GET page loads without errors, the test suite passes.
4. On failure, try deterministic fixes first (a forgotten `bundle install`), then send the agent a fix prompt once or twice. If it still fails, reset git to before the revision.
5. On success, make two commits: one for code, one for documentation.

Every revision runs in a throwaway Docker container (`docker run --rm`). Not perfect isolation, but you don't want an agent with skipped permissions running on your server. Locally it runs on your Claude subscription, so code generation costs nothing extra.

### Previews with Docker and kamal-proxy

How do you preview a Rails app built by another Rails app? Build an image, `docker run` it with the preview hostname it will be served on, curl `/up` until it's healthy, then register it with kamal-proxy via `docker exec` so it's reachable at a per-project subdomain. In development it simply binds to `localhost` on port 3000 plus the project ID.

All of this runs in Solid Queue jobs, and progress is broadcast over Hotwire, so the user sees revisions flip from pending to generating to completed live. The whole app uses only five jobs.

### Decoupling with Active Support notifications

The build side and the preview side never call each other. When a new plan is requested, Hifumi publishes an event via `ActiveSupport::Notifications`. A subscriber enqueues a job to stop any running preview for that project. That's five events in total.

### Export

The code belongs to you. Export pushes the repo, with its per-revision commit history, to a private GitHub repository, and you can keep building in Hifumi afterwards. Paweł showed generated apps ranging from a gym landing page to an HR timesheet app and a fleet manager, most one-shotted or lightly refined.

## My takeaways

- Before handing a feature to an agent, write a phased plan where each phase is a detailed prompt. You can do this without Hifumi.
- Verify every agent step with things you already have: `bundle`, the test suite, and a GET request to every page.
- Run agents with skipped permissions only inside a disposable container.
- Reach for `ActiveSupport::Notifications` when two parts of your app shouldn't know about each other.

Watch the full talk: [From Prompt to Rails: An Online Rails App Generator](https://www.youtube.com/watch?v=0_ZLKWlc7FY)
