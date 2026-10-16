---
layout: post
title: "Rails World 2026: Custom Rails Generators in RubyEvents (Rachael Wright-Munn)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai testing
thumbnail: /assets/thumbnails/youtube/aornGet-EoI.jpg
image:
  path: /assets/images/youtube/aornGet-EoI.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Custom Rails Generators in RubyEvents (Rachael Wright-Munn)"
youtube_id: aornGet-EoI
---

Rachael Wright-Munn is one of the maintainers of [RubyEvents.org](https://www.rubyevents.org), the open source index of Ruby conferences and talks. The talk is a hands-on guide to writing custom Rails generators, plus a small experiment comparing how agents perform with and without them.

## Key ideas

### The problem: YAML and strangers

RubyEvents stores all event data as YAML in the repo: reviewable for spam, editable by anyone, and safe if the app ever disappears. The downside is that every data change is a commit.

Both agents and the 180+ human contributors struggled the same way. They invented keys, used deprecated formats, missed TODO comments, and burned time (or tokens) reverse-engineering examples. Event files also go through phases (speakers announced, schedule released, videos published), and agents mostly see finished files.

Rachael picked **skill + CLI** over an MCP server, so contributors without AI tokens could use the same tool. For the CLI, Rails generators were the obvious fit: arguments, options, ERB templates, help text, tests and file-conflict handling come for free. They are built on **Thor**.

### Building a generator

Start with the generator generator:

```bash
bin/rails generate generator cfp
```

The default class inherits from `Rails::Generators::NamedBase`, which takes a `name` argument and gives you lots of naming helpers. RubyEvents doesn't need a name, so its generators inherit from `Rails::Generators::Base`.

Inputs come in two flavours. **Arguments** are positional, like method arguments. **Class options** are flags in any order, like keyword arguments. Rachael prefers options, because order mistakes disappear. Here is the real CFP generator, trimmed:

```ruby
class CfpGenerator < Generators::EventBase
  source_root File.expand_path("templates", __dir__)

  class_option :name, type: :string, desc: "CFP name", group: "Fields"
  class_option :link, type: :string, desc: "CFP link", group: "Fields"
  class_option :open_date, type: :string, desc: "CFP open date (YYYY-MM-DD)", group: "Fields"
  class_option :close_date, type: :string, desc: "CFP close date (YYYY-MM-DD)", group: "Fields"
end
```

Every `class_option` shows up in `bin/rails generate cfp --help` automatically. The **USAGE** file is appended to that help, and that is where Rachael put examples for each state: a minimal CFP, an ongoing meetup CFP with no end date, a lightning-talk CFP, and how to extend a deadline. When an agent calls `--help`, it gets all that context for free.

Templates are `.tt` files (Thor templates) written in plain ERB. Use `<%-` and `-%>` to trim whitespace in conditional lines, since nothing cleans up YAML the way a browser cleans up HTML. You can also override the templates of Rails' built-in generators by placing your own in `lib/templates`.

### Testing generators

`Rails::Generators::TestCase` gives you `run_generator` (pass the same flags you'd type on the CLI) and `assert_file`. Two gotchas:

- The default setup calls `prepare_destination`, which wipes and recreates one shared `tmp` folder. That gets flaky with parallel tests. RubyEvents uses a unique temp directory per test instead:

```ruby
setup do
  self.class.destination Dir.mktmpdir("cfp_generator", Rails.root.join("tmp").to_s)
end
teardown { FileUtils.remove_entry(destination_root) }
```

- `run_generator` captures stdout, so `binding.irb` appears to hang. Run the test with `RAILS_LOG_TO_STDOUT=true` to see output while debugging. It is documented near the end of the Rails generators guide.

### Generators as MCP tools

The class options already describe everything an MCP tool needs. RubyEvents now has a script that turns each generator into an MCP tool for its server, so a merged generator change shows up as an updated tool after a restart.

### The experiment

Rachael asked GPT 5.4 to add Rails World 2026 from a markdown file, rolling the improvements back in one at a time:

- **No tooling**: four errors, including pulling in 2023 sponsor logos. $1.83 and 136,000 tokens.
- **Generators only**: two errors.
- **Generators + skill**: one error, swapping em dashes for hyphens.
- **MCP**: cheapest, but it quit halfway with no videos, schedule or sponsors.

The surprise came from smaller models. With good tools, a small model finished one run for 39 cents with zero mistakes, because it didn't go off script or rewrite descriptions. Rachael's conclusions: skills made fewer mistakes but cost more, and the token cost of MCP may be overblown.

## My takeaways

- Tell your agent to use Rails generators (including `rails g migration`) instead of writing files by hand.
- Write a custom generator for the thing your team creates most often, and put real examples in its USAGE file.
- Customize the default scaffold templates in `lib/templates` to match your conventions.
- For narrow, repeatable tasks, try a smaller model with a good CLI before reaching for the biggest one.

Watch the full talk: [Custom Rails Generators in RubyEvents](https://www.youtube.com/watch?v=aornGet-EoI)
