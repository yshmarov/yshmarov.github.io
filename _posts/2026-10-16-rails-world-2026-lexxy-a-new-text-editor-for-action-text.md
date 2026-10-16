---
layout: post
title: "Rails World 2026: Lexxy: a new text editor for Action Text (Jorge Manrubia)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails action-text lexxy javascript
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: UIXwabQ9jIU
---

Jorge Manrubia from 37signals explained why they replaced Trix with **Lexxy**, an open-source rich text editor built on Meta's Lexical, and announced that Lexxy is heading to be the **new Action Text default**. If your app uses `rich_text_area`, your editor is about to change, and this talk explains why.

## Key ideas

### Why Trix hit a wall

Trix shipped in 2015 and has been the Action Text editor since Rails 6. It's simple and battle-tested, but two problems kept coming back:

- **The document model.** Trix stores a flat list of blocks with attributes. A bullet inside a blockquote is one block labelled with both, and the nesting only exists at render time. That keeps the HTML clean, but a table (rows containing cells containing arbitrary content) can't be represented. Customers asked for tables in Basecamp and 37signals couldn't build them.
- **Maintenance.** Modern editors sit on `contenteditable`, which behaves differently across browsers and breaks when operating systems update. In 2024 a series of iOS releases broke Trix's autocomplete, dictation and cursor handling, which Jorge called close to a code red.

Over the years they tried adding tables to Trix (2022), a TipTap spike for HEY (2023), and the Markdown editor they built for Writebook (2024), which didn't work for general-purpose products. In 2025 they evaluated TipTap again and passed: Jorge said they didn't want to depend on an open-source core backed by a VC-funded company whose incentives could push features behind a paywall later.

### Why Lexical

Lexical has a tiny core with no dependencies. It treats `contenteditable` as an input/output and rendering surface rather than the source of truth, which is the same idea Trix had. The source of truth is an **immutable document model**: every edit produces a new snapshot, and a reconciler diffs snapshots into the DOM, similar to React's virtual DOM. Commands (an event bus) and node transforms make it extensible, and the features (rich text, Markdown, tables, clipboard) live in separate packages.

Meta uses Lexical in its own products, so obscure keyboard and device bugs get found and fixed upstream at a scale 37signals could never match.

### What Lexxy adds

Jorge said Lexxy is around 13,000 lines of vanilla JavaScript on top of Lexical, spent on details like a cursor between two adjacent images or pasting from Microsoft Word.

Features: tables, highlight colors, Markdown shortcuts, real-time code highlighting via Prism, image galleries with drag and drop, links created by pasting a URL, attachment previews for PDFs and videos, and a **prompts API** for mentions, emoji pickers and similar menus.

They also put serious work into:

- **Speed:** keystroke-to-render stays well under the 50 ms threshold where typing starts to feel sluggish. Open the [Lexxy sandbox](https://lexxy.dev/sandbox/) next to Trix and type to feel it.
- **Accessibility:** led by Bruno Prieto. Semantic HTML, focus management, arrow-key toolbar navigation, Alt+F10 to jump between editor and toolbar, and keyboard reordering of images.
- **Security:** its own DOMPurify instance, URL sanitization, and restricted attachment and node types.
- **Extensions:** an API on top of Lexical's extension system for new node types, commands and toolbar buttons. Basecamp's voice notes are built with it.

Timeline: first used in Fizzy (December 2025), then Basecamp 5 (May 2026). Jorge announced **Lexxy 1.0** at the talk.

### Action Text integration

Action Text normalizes attachments into its own canonical HTML. Lexxy emits that format directly, so the stored content doesn't depend on the editor. Rails main (8.2) now has an **editor adapter** API, built by Sean Doyle from thoughtbot, with one implementation for Trix and one for Lexxy:

```ruby
# config/application.rb
config.action_text.editor = :lexxy
```

The Lexxy gem sets this for you on Rails 8.2. On Rails 8.0 and 8.1 it overrides the Action Text form helpers so `form.rich_text_area` renders Lexxy.

### Building it with agents

Lexxy was Jorge's first big project built with Claude from the start. Two lessons:

- Moving editor interaction tests from Capybara to **Playwright** (better low-level focus and keyboard primitives, multiple browsers) made agents far better at writing them.
- When he ran 10 to 15 agents fixing bugs in parallel (almost 300 bugs and polish items before and after Basecamp 5), review became the bottleneck. A skill reproduces each bug in the production sandbox with a fresh context, re-runs the same script against the fix locally, and labels the PR when both checks pass.

## My takeaways

- For a new Rails app, Jorge's advice is to **use Lexxy now** (`gem "lexxy"`) instead of Trix.
- Existing Trix apps without heavy customizations should migrate without much trouble. Basecamp did exactly that.
- For browser-heavy test suites written with agents, try Playwright for the low-level interaction tests.

Watch the full talk: [Lexxy: a new text editor for Action Text](https://www.youtube.com/watch?v=UIXwabQ9jIU)
