---
layout: post
title: "Replacing wicked_pdf with sghtmltopdf: no Chrome, no Node"
author: Yaroslav Shmarov
tags: ruby-on-rails pdf wicked_pdf sghtmltopdf html-to-pdf kamal docker
thumbnail: /assets/thumbnails/pdf.png
---

HTML to PDF in Ruby is weird:

- gem [wicked_pdf]({% post_url 2021-05-24-gem-wicked-pdf %}) relies on dead `wkhtmltopdf`;
- gem Grover requires Node;
- WeasyPrint requires Python;
- gem [Ferrum]({% post_url 2024-01-27-gem-ferrum-generate-pdf %}) requires headless Chrome;
- gem Prawn is not HTML;
- gem [DocRaptor]({% post_url 2023-12-02-docraptor-html-to-pdf %}) wraps expensive PrinceXML.

[@yo_waka](https://x.com/yo_waka) has a new solution: [sghtmltopdf](https://github.com/waka/sghtmltopdf) — an HTML-to-PDF engine written in Rust with **no browser inside**, shipped as a precompiled native extension that renders in-process. No subprocess, no binary, no Node.

There is a [discussion on Reddit](https://www.reddit.com/r/rails/comments/1vln5xn/still_on_wicked_pdf_i_wrote_a_pdf_renderer_that) worth reading first.

Why this matters: `wkhtmltopdf` was archived in 2023 — a fork of a 2014-era QtWebKit with unpatched CVEs, no flexbox, no grid. And if your production image is `ruby:slim` on a small box, adding Chromium costs ~350MB for the privilege of rendering three invoices a day.

I migrated a Rails 8 CRM to it. The `render pdf:` API is unchanged and the whole diff is small — but I shipped **two production regressions** on the way, both of which rendered a perfectly valid PDF that was silently wrong. Here is the working setup, then every trap in the order I hit it.

## The working setup

### 1. The gem

```ruby
# Gemfile
gem 'sghtmltopdf'
```

Precompiled for `x86_64-linux`, `aarch64-linux`, `x86_64-linux-musl`, `aarch64-linux-musl` and `arm64-darwin`. Ruby >= 3.2. No Rust toolchain needed. Windows and Intel Mac are not supported at all.

### 2. The initializer

```ruby
# config/initializers/sghtmltopdf.rb
Sghtmltopdf.configure do |c|
  c.page_size = 'A4'

  c.margin_top = '10mm'
  c.margin_right = '10mm'
  c.margin_bottom = '10mm'
  c.margin_left = '10mm'

  c.font = [
    Rails.root.join('vendor/fonts/DejaVuSans.ttf').to_s,
    Rails.root.join('vendor/fonts/DejaVuSans-Bold.ttf').to_s
  ]
end
```

Options are the CLI long options with `--` dropped and `-` turned into `_`. Note it is a **flat hash** — wicked_pdf's nested `margin: { top: 10 }` is rejected on purpose, because wicked_pdf read bare numbers as mm and this reads them as px. Write the units out.

### 3. The controller

Unchanged.

```ruby
def show
  respond_to do |format|
    format.html
    format.pdf { render template: 'projects/show', pdf: "invoice #{@project.id}" }
  end
end
```

### 4. The Dockerfile

Delete wkhtmltopdf's runtime dependencies. Mine had been carrying these for years:

```diff
 RUN apt-get update -qq && \
-    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client \
-    libfontconfig1 libxrender1 libxext6 xfonts-75dpi xfonts-base && \
+    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
```

The image got *smaller*.

---

Now the traps.

## Trap 1: your lockfile probably has no platforms

Adding the gem broke `bundle exec` locally:

```
Could not find nokogiri-1.19.4 in locally installed gems (Bundler::GemNotFound)
```

My `Gemfile.lock` listed only the `ruby` platform. sghtmltopdf publishes platform-specific gems, and adding one changes how Bundler materialises *everything*.

```sh
bundle lock --add-platform x86_64-linux arm64-darwin
bundle install
```

Use your **deploy** architecture, not your laptop's. Mine is `amd64` (`config/deploy.yml`), so `x86_64-linux`. Get this wrong and the Docker build tries to compile the Rust extension from source, which defeats the entire point.

Side effect worth knowing: other native gems now resolve to precompiled Linux builds inside Docker too. Builds get faster, but it is a real change to how every gem installs.

## Trap 2: remote assets are forbidden by default

All three of my templates pulled Bootstrap from a CDN:

```haml
%link{:href => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css", :rel => "stylesheet"}
```

sghtmltopdf renders in-process with no HTTP server, and `--allow-remote-assets` is **off by default**. That `<link>` silently does nothing and every table border disappears.

There is a flag to enable it, but do not. Vendor the CSS instead — it takes a network fetch out of the render path. I inlined only the Bootstrap 3 subset my templates actually use (tables, `text-center`, `pull-right`, heading sizes) into `app/assets/stylesheets/pdf.css` at the real 3.4.1 values.

## Trap 3: your production image has no fonts

Fonts are resolved at conversion time and embedded. `ruby:slim` ships **none**. My invoices are almost entirely Ukrainian, so without an explicit font they render as tofu — `□□□□`.

Vendor a font with the coverage you need and pass it explicitly:

```ruby
c.font = [
  Rails.root.join('vendor/fonts/DejaVuSans.ttf').to_s,
  Rails.root.join('vendor/fonts/DejaVuSans-Bold.ttf').to_s
]
```

Two things here:

- **List both weights.** With only the regular face, bold headings get a synthesised stroke instead of real bold outlines.
- **TTF/OTF only.** WOFF/WOFF2 raise an error, so you cannot point at the webfont you already serve.

Paths passed via `font:` are exempt from the `allow` sandbox the railtie sets up. If you install a system font package instead (`apt-get install fonts-dejavu-core`), you must add `/usr/share/fonts` to `allow` yourself, because it is outside `Rails.root`.

## Trap 4: the stylesheet helper fails silently

This one reached production.

The gem ships `sghtmltopdf_stylesheet_link_tag`, a drop-in for wicked_pdf's version that inlines CSS into a `<style>` tag. Every local environment rendered perfectly. Production rendered **every PDF with no stylesheet at all** — no borders, wrong sizes, everything bold.

Everything bold, because both templates wrap their content in `%h6`, and the browser-default `font-weight: bold` is exactly what the missing Bootstrap was overriding.

The helper resolves the asset through `public/assets` and, when the lookup fails, [returns an empty string rather than raising](https://github.com/waka/sghtmltopdf/blob/main/bindings/ruby/lib/sghtmltopdf/view_helpers.rb):

```ruby
def sghtmltopdf_stylesheet_link_tag(*sources)
  css = sources.flatten.filter_map do |source|
    path = sghtmltopdf_asset_path(with_extension(source, ".css"))
    File.read(path) if path
  end
  return "".html_safe if css.empty?   # <- this
  content_tag(:style, css.join("\n").html_safe, type: "text/css")
end
```

So the document renders happily with zero styles and still returns a structurally valid, normally-sized PDF.

I never established *why* the lookup fails in my container. I checked all of it: the precompiled asset is present, byte-identical to a local build, and served over HTTP at exactly the digest `asset_path` produces. A local `RAILS_ENV=production` boot resolves it correctly. It does not reproduce outside the container.

Rather than keep debugging in production, I removed the dependency. `pdf.css` is plain CSS whose only consumer is the PDF templates, so read it from a fixed path:

```ruby
# app/helpers/pdf_helper.rb
module PdfHelper
  PDF_STYLESHEET = Rails.root.join('app/assets/stylesheets/pdf.css')

  def pdf_stylesheet_tag
    # Escaping would turn the child combinators in `.table > thead > tr > th`
    # into &gt; and silently break every table rule.
    css = PDF_STYLESHEET.read.html_safe # rubocop:disable Rails/OutputSafety
    content_tag(:style, css, type: 'text/css')
  end
end
```

```haml
%head
  %meta{:charset => "utf-8"}/
  = pdf_stylesheet_tag
```

Deterministic in every environment, and `Pathname#read` raises if the file is ever moved instead of quietly dropping every rule.

**Keep it as `.css`, not `.scss`.** The gem's helper `File.read`s the asset straight off disk when it is not precompiled into `public/` yet — so a `.scss` file gets inlined *uncompiled* in development. The same applies to reading it yourself.

## Trap 5: long words print on top of the next cell

The second regression to reach production. A single long unbreakable word — `Відповідальний` — printed across the column border and on top of its neighbour instead of wrapping or widening the column.

This is documented behaviour, in the [properties reference](https://waka.github.io/sghtmltopdf/supports/properties.html):

> `table-layout: auto` では列の自然幅をクランプする形で効くため、表を紙幅に収める比例縮尺の後は `min-width` が保証されない

*("in `table-layout: auto` it clamps the column's natural width, so after the proportional scaling that fits the table to the paper width, `min-width` is not guaranteed")*

The table is scaled down proportionally to fit the page, past the point where the column can hold its longest word. wkhtmltopdf never needed help because it gave the column its minimum content width instead.

```css
.table > thead > tr > th,
.table > thead > tr > td,
.table > tbody > tr > th,
.table > tbody > tr > td {
  overflow-wrap: break-word;
}
```

`break-word` only splits a word that would not fit even on a line of its own, so ordinary text still wraps at spaces. Note `word-break: break-word` is **not** supported (the deprecated value); use `overflow-wrap` or `word-break: break-all`.

## Trap 6: reproducing a layout bug in isolation

Worth its own section, because it cost me two wrong attempts and it is exactly where an AI agent will confidently produce a broken repro.

I could not reproduce the overflow above in a standalone HTML file. Twice. The markup is misleading in two separate ways:

**The tables have no `<tr>`.** The HAML is `%thead > %th` directly. The HTML5 parser inserts an implied row, so it *works* — but if you hand-write a repro with `<tr>` wrappers, you are not testing the same tree.

**The `%h6` is not where you think.** The whole document is wrapped in `%h6`, but the HTML5 parser **closes an open `h1`–`h6` on the next heading start tag**. There is an `%h4` above the first table, so the `h6` ends there and the tables actually render at body size (14px), not h6's 12px.

At 12px the word fits and nothing overflows. My first two repros were inside the `h6`, rendered at 12px, and looked fine. Only after matching the real font size did the bug appear — identical to production.

If you cannot reproduce a rendering bug, dump the actual generated HTML before theorising about CSS:

```ruby
html = ApplicationController.render(
  template: 'projects/show', formats: [:pdf], assigns: { project:, jobs: }
)
```

## The testing lesson

This is the part I would tattoo on an agent.

My first test suite asserted the response was `application/pdf`, that the body started with `%PDF-`, and that it was over 5KB. All of it passed against **both** production regressions.

An unstyled page is still a structurally valid, normally-sized PDF. A size floor cannot distinguish a styled document from an unstyled one.

Assert that the rules actually reach the document:

```ruby
test 'pdf templates inline the stylesheet' do
  html = ApplicationController.render(
    template: 'projects/show', formats: [:pdf],
    assigns: { project:, jobs: project.jobs }
  )

  assert_includes html, '<style'
  assert_includes html, '.table-bordered', 'stylesheet rules missing from the document'
  assert_includes html, 'page-break-inside'
  assert_includes html, 'overflow-wrap'
end
```

And check that a test can fail. I stubbed the helper to return `""` and confirmed this turns red — the failure output printed the same empty `<head>` production had been generating.

For the font, assert an embedded font exists rather than trusting the config:

```ruby
assert_match(%r{/FontFile2}, response.body, 'expected an embedded TrueType font')
```

None of this replaces looking at the output. I rendered every document to PDF, converted to PNG with `qlmanage -t -s 1400 -o . out.pdf`, and compared against screenshots of the old wkhtmltopdf output. That is what caught the column widths.

## What you actually get

- No Chrome, no Node, no `wkhtmltopdf` binary
- ~15MB gem in, five apt packages out — a *smaller* runtime image
- Renders in-process, no subprocess or tempfile handoff, GVL released during layout so Puma keeps serving
- Typed exceptions (`Sghtmltopdf::UsageError`, `RenderError`, …) instead of silent failure — unknown options raise instead of being ignored

## What you give up

No JavaScript at all — `<script>` is skipped. CSS support is a documented subset: no grid gradients, no multi-column, no `:is()`/`:where()`/`:has()`, no `position: sticky`, no SVG or GIF images, no PDF outlines. Check the [property support table](https://waka.github.io/sghtmltopdf/supports/properties.html) against your templates before committing to this.

For old Bootstrap 3 table layouts like mine, none of that matters. For a template built on flexbox with a Chart.js canvas in it, this is the wrong tool and you want a browser.

## Should you use it?

The honest caveat: at the time of writing, sghtmltopdf is at **0.1.1** and a few weeks old. That is the whole risk.

I took it anyway, and the reason is worth stating because it generalises: **the blast radius is small and the revert is two lines.** The render path is self-contained, the controller API is identical to wicked_pdf's, and failures raise typed exceptions rather than corrupting data. If it disappoints, `git revert` and you are back on wicked_pdf.

That is a cheap bet. Migrating your ORM on a three-week-old gem is not the same bet at all.

If you want a proven engine and can accept a Python runtime in the image, WeasyPrint is far more mature and does the same job — but the Ruby wrappers are all thin abandoned shells, so you own the subprocess call. If you can accept the browser, [ferrum_pdf]({% post_url 2024-01-27-gem-ferrum-generate-pdf %}) is the pure-Ruby-to-Chrome option. If you want to never think about an engine again, Prawn has 100M downloads and no binaries — at the cost of rewriting your templates in a DSL.

## Migration checklist

For humans and agents, in the order that avoids rework:

1. `bundle lock --add-platform <your deploy arch>` — check `config/deploy.yml`, not your laptop
2. Vendor any CDN stylesheet into a local plain-CSS file; delete the `<link>` tags
3. Vendor a TTF/OTF with your script's coverage, list regular **and** bold
4. Pin `page_size` and margins explicitly — the default is 1 inch, wkhtmltopdf's was 10mm
5. Inline the stylesheet from a fixed path, not through the asset pipeline
6. Add `overflow-wrap: break-word` to table cells
7. Delete wkhtmltopdf's apt packages from the Dockerfile
8. Write a test that asserts CSS rules reach the document — then break it on purpose to prove it fails
9. Render every document and *look at it* next to the old output
