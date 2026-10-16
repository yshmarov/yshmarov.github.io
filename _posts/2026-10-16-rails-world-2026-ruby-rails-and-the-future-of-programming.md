---
layout: post
title: "Rails World 2026: Ruby, Rails, and the future of programming (Matz, DHH and Jeremy Daer)"
author: Yaroslav Shmarov
tags: rails-world conference ruby ruby-on-rails ai
thumbnail: /assets/thumbnails/youtube/IEOqgPfGLQ8.jpg
image:
  path: /assets/images/youtube/IEOqgPfGLQ8.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Ruby, Rails, and the future of programming (Matz, DHH and Jeremy Daer)"
youtube_id: IEOqgPfGLQ8
---

A fireside chat with Yukihiro Matsumoto (Matz) and DHH, moderated by Jeremy Daer of 37signals. The question on the table: what does it mean to be a Rubyist when agents write most of the code? Fewer slides and more opinions than the keynotes, but there are a few concrete projects in it worth knowing about.

## Key ideas

### Identity outlives practice

Jeremy asked the room who still feels like a Rubyist. Every hand went up, even though most people there no longer write much Ruby by hand. Matz admitted to no longer using Emacs as the main code editor, something unimaginable two years ago.

DHH's framing: the software engineer label never fit him. For years he called himself a software writer, and now he calls himself a **software maker**, which he finds more satisfying. What a Rubyist brings to agent work is taste, a sense of proportion and beauty, the same things we cared about when writing Ruby. He described the shift as speedrunning the stages of grief, and said there should be room for nostalgia on the way to acceptance.

### Spinel: Matz's Ruby compiler

The most concrete news: since March, Matz has been working on **Spinel**, an ahead-of-time compiler that turns a performance-friendly subset of Ruby into a native binary. In Matz's tests, real-world programs used a small fraction of the memory of CRuby. Matz sees it as a way for Ruby to stay relevant when people pick languages for runtime cost.

Jeremy also mentioned **Roundhouse** (Sam Ruby's project), which treats a Rails app as a spec that a compiler can turn into other targets, including plain Ruby without Rails.

### Everyone has core committers now

Matz jokes about vibe coding Ruby for 15 years: propose a feature, let the core committers build it, review and merge. Now everyone has that setup. Matz described waking up to 20 new issues on the Spinel repo during the conference and having Claude resolve 12 of them before DHH's keynote ended.

DHH told the same story about Rails: he wrote nearly all of version 1, about half of version 2, and very little after that. Directing is the job.

### On slop

- DHH calls the slop argument "90% cope". If you copy error messages between your terminal and an agent, you are acting as a meat proxy; let the agent read the errors itself.
- He prefers issues and PRs written by agents to average human ones, treats them as suggestions, and has his own agent rewrite the implementation. Nobody is attached to the lines, so nobody is hurt when they get replaced.
- Trust an agent like a new hire: check in less often as it proves itself, and accept it will sometimes be wrong, like people are.

### Token efficiency and languages

Matz shared that a colleague compared about a dozen languages for token and time efficiency. Ruby, Python and plain JavaScript came out on top, and **static typing did not help**. DHH added that models don't need tons of Ruby in their training data to write it well: the principles of good software are universal, and agents will happily speak Ruby if you ask them to.

### Matz's worry: invisible foundations

Matz's biggest concern was sustainability. The more we build through agents, the less visible the underlying pieces become: the Ruby interpreter, Rails, Linux, PostgreSQL. If society stops noticing them, it stops maintaining them.

### What stays

Both closed on the same values: motivation, joy and freedom. DHH said he will still start every new web app in Rails, since most Rails apps could run on a Raspberry Pi, and rewrite a hot path in something faster only if it ever becomes economically worth it.

## My takeaways

- Stop being the meat proxy. Give your agent access to test output, logs and error pages directly instead of pasting them in.
- Keep an eye on Spinel. It is experimental, but a Ruby subset that compiles to a small native binary could change where Ruby gets used.
- Ask your agent to explain unfamiliar code in Ruby. It is still the most readable way to understand an algorithm.
- Support the open source you depend on. If agents make Ruby and Rails invisible, maintainers become the scarce resource.

Watch the full talk: [Ruby, Rails, and the future of programming](https://www.youtube.com/watch?v=IEOqgPfGLQ8)
