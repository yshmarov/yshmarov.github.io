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

Do not review DRAFT Pull Requests.

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

#### Views

Do not disable turbo by default in the app. The limitations of turbolinks are irrelevant in 2023.

Do not use `<a>` tag. Use `link_to` instead.

Do not embed SVG code in an HTML page. Store the SVG as a separate object and use gem `inline_svg` to render it.

Prefer using ViewComponents over _partials. Here are some rules of thumb:
- logic that you would pass in locals? **VC**
- view rendering logic? **VC**
- non-reusable HTML abstraction? **partials**
- reusable HTML? **partials**

When using ViewComponent, try to store all the view login in the `.rb` file, not in the `.html.erb` file.

Do not store view logic in a Rails model. Use `app/helpers`, `app/components`, `app/decorators` instead.

Do not use jQuery and jQuery-based libraries.

If you can't render a turbo_stream as a one-liner in a controller, use a `*.turbo_stream.erb` template.

When writing text, use "sentence case capitalization":
- Bad: *"These Are Some Words"*
- Good: *"These are some words"*

#### Design patterns

Use `app/services` to extract complex logic and test it in isolation.

As you application gets complex, you can use a more advanced system of design patterns:
- `app/services` for working with exteranal APIs (`Twilio::SendSms`)
- `app/operations` for working with (`Book::GenerateBarcode`)
- `app/interactors` for extracting logical sequences (`if Book::GenerateBarcode.success? ? Twilio::SendSms`)

#### Models

When doing database migrations, don't forget to validate `null` and `default` on the database level.

Avoid using ActiveRecord callbacks. Call methods explicitly when needed.

#### Testing

Always use a CI tool for:
- code style: rubocop, prettier, erblint
- tests

Minitest is okay, but Rspec is better. FactoryBot is more useful that fixtures.

When testing, focus on writing good **Controller** and **System** tests.

🤔💭 I will be adding more to the list, if I remember something.

#### Other

Prefer storing text in `en.yml` i18n file and inheriting from there.
- Bad: `redirect_to posts_path, notice: 'post created!'`
- Good: `redirect_to posts_path, notice: t('.success')`

Prefer symbols over strings:
- Bad `"payment pending"`
- Good: `:payment_pending`

Use gem Pagy for pagination. WillPaginate and Kaminari are simply not as great.

Do not use [magic `strftime`]({% post_url 2022-06-10-stop-using-strftime %})

Do not use magic strings:
- Bad: `tax_amount = price * 0,17`
- Good: `TAX_AMOUNT = 0,17` && `tax_amount = price * TAX_AMOUNT`
