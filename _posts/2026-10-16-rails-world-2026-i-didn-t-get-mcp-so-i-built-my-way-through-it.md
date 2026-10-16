---
layout: post
title: "Rails World 2026: I Didn't Get MCP, So I Built My Way Through It (Enrique Mogollan)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai mcp testing
thumbnail: /assets/thumbnails/youtube/km2hEx-HEME.jpg
image:
  path: /assets/images/youtube/km2hEx-HEME.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: I Didn't Get MCP, So I Built My Way Through It (Enrique Mogollan)"
youtube_id: km2hEx-HEME
---

Enrique Mogollan from Handshake didn't understand what MCP actually does on the wire, so he built an MCP inspector in Ruby to watch the messages. That turned into **Coatepec**, an MCP server that gives coding agents a fast, token-cheap way to run tests and inspect a Rails app. If your agent spends half its context reading test output, this talk is relevant to you.

## Key ideas

### What MCP looks like on the wire

The short definition: MCP is how an agent pulls data from an external source into its context window without you pasting it in. Underneath:

- **Two transports:** stdio for local servers, and **streamable HTTP** for remote ones. The older HTTP + server-sent events transport is deprecated in favor of streamable HTTP.
- **Every message is JSON-RPC**, so every conversation has the same shape: `initialize`, then list tools / resources / prompts, then call them.
- Every tool comes with a JSON schema describing how to call it, and responses carry a lot of extra fields.

Enrique explained the context window with a night-sky metaphor: tokens are stars, the visible sky is your context window, attention is the lines that make constellations, and MCP is how you add more stars to the sky.

### The problem: light pollution

While upgrading Rails at work, he had an agent running the test suite around 50 times a day. Each run meant about 8 seconds of Rails boot, and the output (errors, warnings, deprecations) flooded the context. Most of it was noise, and it made the useful signal harder for the agent to find.

### Coatepec

[Coatepec](https://github.com/mogox/coatepec) (named after a coffee town in Veracruz) is an MCP server that runs as a **sidecar with a warm Rails process**. The agent asks it to run a test, list routes or describe a model. Since Rails is already booted, model and route lookups come back almost instantly, and test runs are faster than calling `bin/rails` directly.

Install it once, outside your app's bundle, and point it at the app:

```bash
gem install coatepec mcp
claude mcp add coatepec --scope project -- coatepec --root .
```

That writes a project-scoped `.mcp.json` you can commit for the whole team. The README says explicitly not to add it to the app's Gemfile.

Details from the talk:

- **Fork beats spawn.** On macOS, spawning a fresh process for each test run was as slow as plain `bin/rails`. Forking the warm worker is where the speedup came from. Each fork gets its own database connection, and a lock lets several runs share it safely.
- **Small JSON responses.** Over several versions he cut token use by about 90%, mostly by dropping headers and full error paths and returning which tests passed and which failed. The output was tidy enough that Claude turned it into a table without being asked.
- **Deliberately limited.** Spec runs (Minitest-compatible too), models and routes, with optional Rails engine support. No eval, no console, no raw SQL. It's meant for development work only.
- **Subagents cost more than you'd think.** His first plan was a skill telling the agent to always run Coatepec in a subagent to protect the main context. That works, but each subagent's setup burns tokens. Unless your token budget is unlimited, he recommends skipping the subagent.

### MCP Apps

The last part showed **MCP Apps**, the first official MCP extension. A tool can declare a UI, and the server returns HTML, CSS and JavaScript that the client renders in a sandboxed iframe, with access to the server's tools. Enrique embedded one in a Rails page with an MCP client and an iframe: a coffee-shop card where changing the rating called the server and got an animation back. The same UI shows up inside an agent's chat window. Why use this over a regular API? Because MCP is built for agents.

## My takeaways

- Watch the raw JSON-RPC between your agent and an MCP server at least once. Anthropic's Node inspector works for that.
- If agents run your test suite often, keep their output small: a warm process plus compact pass/fail JSON saves both time and context.
- Measure before you put work into subagents. They save main-context tokens but can cost more in total.
- Keep an eye on MCP Apps if you'd like your Rails features to appear inside AI chat clients.

Watch the full talk: [I Didn't Get MCP, So I Built My Way Through It](https://www.youtube.com/watch?v=km2hEx-HEME)
