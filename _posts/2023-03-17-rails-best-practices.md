---
layout: post
title:  Best practices for writing and collaborating on Rails code
author: Yaroslav Shmarov
tags: ruby-on-rails best-practices design-patterns
thumbnail: /assets/thumbnails/rails-logo.png
---

Here are some best practices for writing code and working better together as a team.

These same principles were used in all the organizations I worked in and apply to any Rails dev team.

### 1. Teamwork

Prefer written communication.

Have meetings only when writing would take longer.

Promote independency in decision making.

### 2. Coding together

`main`/`master` branch should accept changes only via Pull Request.

Pull Request should require 1 approval and a passing CI to be merged.

Do not merge a PR if you are not the author.

Trust your colleagues best intentions.

If you are stuck - ASK FOR HELP.

Pair coding can help in getting unstuck and create a "productivity rush".

### 3. Coding in general

The less code you write, the less code there is to maintain. In a mature app, aim to be "code-neutral" (delete at least as much as you add).

Do not overcomplicate. Look for the shortest good path to solve a problem.

Do not reinvent the wheel. Search for an existing solution before rolling out your own.

Good code does not require a lot of comments to explain it.

### 4. Writing Rails code

Avoid using ActiveRecord callbacks. Call methods explicitly when needed.

Do not disable turbo by default in the app. The limitations of turbolinks are irrelevant in 2023.

Do not use `<a>` tag. Use `link_to` instead.

Do not embed SVG code in an HTML page. Store the SVG as a separate object and use gem `inline_svg` to render it.

Do not store view logic in a Rails model. Use `app/helpers`, `app/components`, `app/decorators` instead.

Prefer using ViewComponents over _partials. Here are some rules of thumb:
- logic that you would pass in locals? **VC**
- view rendering logic? **VC**
- non-reusable HTML abstraction? **partials**
- reusable HTML? **partials**

When using ViewComponent, try to store all the view login in the `.rb` file, not in the `.html.erb` file.

Do not use jQuery and jQuery-based libraries.

If you can't render a turbo_stream as a one-liner in a controller, use a `*.turbo_stream.erb` template.

When testing, focus on writing good Controller and System tests.

Use `app/services` to extract complex logic and test it in isolation.

As you application gets complex, you can use a more advanced system of design patterns:
- `app/services` for working with exteranal APIs (`Twilio::SendSms`)
- `app/operations` for working with (`Book::GenerateBarcode`)
- `app/interactors` for extracting logical sequences (`if Book::GenerateBarcode.success? ? Twilio::SendSms`)

🤔💭 I will be adding more to the list, if I remember something.
