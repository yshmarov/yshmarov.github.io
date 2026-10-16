---
layout: post
title: "Rails World 2026: Closing keynote (Aaron Patterson)"
author: Yaroslav Shmarov
tags: rails-world conference ruby performance security
thumbnail: /assets/thumbnails/youtube/t0knYnEYBRo.jpg
image:
  path: /assets/images/youtube/t0knYnEYBRo.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Closing keynote (Aaron Patterson)"
youtube_id: t0knYnEYBRo
---

Aaron Patterson (Shopify's Ruby and Rails infrastructure team) closed Rails World 2026 with two talks in one: how Ruby optimizations decide what they are allowed to change, and the strange story of agents attacking RubyGems.org. He also announced from the stage that **Mike Dalessio** (Nokogiri, sqlite3 gem, Rails security team) has joined the Rails core team.

## Key ideas

### The as-if rule

Aaron reframes the saying *the purpose of a system is what it does*: it depends on who is observing it. Compiler writers call this the **as-if rule** (codified in C++): an optimization may change anything, as long as nobody can observe a difference. Every optimization has two sides: what gets deleted, and who could notice.

### Memoization and Ractors

The classic `@result ||= expensive_call` assumes one observer at a time. With Ractors running in parallel, a class-level memoized ivar becomes a real race. The upside: Ractors **raise an exception** instead of silently corrupting data.

For framework code, Rails has `ActiveSupport::Ractors.on_main`, which runs a block on the main Ractor so it can write a class-level ivar. Aaron warned that pushing too much work there makes the main Ractor a bottleneck. Where possible, use Koichi Sasada's **ractor-sharing** gem:

- `Ractor::LockVar` guarantees a computation runs exactly once. Use it when the work is not idempotent.
- `Ractor::TVar` allows it to run more than once. Use it when repeating the work is harmless.

Aaron expects the blast radius to be small: in a Ractor-per-request server, most allocations happen inside the request, and constants and config are the main shared touch points.

### Ractor-local GC

According to Aaron, Ruby 4.1 will ship a **Ractor-local garbage collector** with a separate heap per Ractor, removing the contention when parallel Ractors all ask one GC for objects. The catch: objects can be shared between Ractors, sometimes implicitly. Deduplicated JSON keys, for example, point into the main Ractor's heap, so an occasional global GC is still needed.

### Missing stack frames

Two examples of Ruby quietly bending the as-if rule:

- Active Support callbacks keep backtraces short, until you add an `around` callback.
- On Ruby 4.0, `Foo.new` inlines the call to `initialize` when `new` is the default implementation, so the `Class#new` frame disappears from backtraces. Aaron's example allocates about 70% faster than before, without a JIT.

Almost nobody cares about those frames, which is what makes these optimizations possible.

### ZJIT bets and deoptimization

ZJIT makes riskier bets: that you won't redefine methods, operators like `+` or constants, and that no TracePoint is watching. Its IR contains **patch points**, markers with no machine code. When an assumption breaks, ZJIT overwrites the compiled code with a jump to an exit that restores the VM state. Inspect the IR yourself:

```bash
ruby --zjit --zjit-dump-hir --zjit-call-threshold=1 -e "1 + 1"
```

Then the promised AI part, which turns out to be **abstract interpretation**. ZJIT pretends to run code over an abstract heap, inlines a Rack app's `call`, notices the `[status, headers, body]` array is never used as an array, and deletes it. In his demo, 1,000 requests allocated about 1,000 objects on the interpreter and on YJIT, and 8 on ZJIT.

### RubyGems and the GemStuffer campaign

In May, thousands of junk gems hit RubyGems.org and signups were paused; Socket.dev named it **GemStuffer**. The gems contained a script that scraped UK government pages and repackaged the results as new gems.

Aaron couldn't see how the script ever ran until researchers explained it. The gems shipped a `.yardopts` file that loaded `script.rb`. RubyGems.org sent a webhook to RubyDoc.info, which built the docs in a container that still had network access, so the script ran and uploaded the next gem.

Some gems went further and tried to exploit a separate bug: Fastly was caching legacy `GET` responses to the API-key endpoint, so a request without credentials could get back someone else's key. It was reported independently in July and fixed within days. The rubyhack.ai report, published in September, attributes the campaign to OpenAI agents. As far as anyone knows, nobody was harmed.

### Keep reading your code

Aaron calls himself an optimist, but he rejects the argument that AI is just the next compiler. A compiler promises the as-if rule. In his words, "there is no as-if rule for your English", so he will keep reading his code.

## My takeaways

- Search your app for class-level `||=` memoization. That is where Ractor errors will show up first.
- Try ZJIT on a benchmark and read the HIR dump. It shows what the JIT assumes about your code.
- Don't depend on exact backtraces or allocation counts in tests. Ruby is allowed to change them.
- Review the agent-written code you ship. Nothing guarantees it behaves as if you wrote it.

Watch the full talk: [Closing Keynote](https://www.youtube.com/watch?v=t0knYnEYBRo)
