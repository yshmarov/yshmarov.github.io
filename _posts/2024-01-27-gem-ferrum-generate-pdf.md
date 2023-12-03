---
layout: post
title: Generate PDF with Ferrum (headless Chrome API)
author: Yaroslav Shmarov
tags: ruby-on-rails ferrum pdf html-to-pdf headless-chrome
thumbnail: /assets/thumbnails/pdf.png
---

Usually I would use an HTML-to-PDF library to to generate and display a PDF.

**An absolutely different**, alternative way to view or download a page as PDF would be via a **headless browser API**.

[Gem Ferrum](https://github.com/rubycdp/ferrum) lets you open a headless chrome browser and perform different actions (click link, take screenshot, open as PDF, etc.)

Why not use Ferrum to open or save a file as PDF?

Here's how it could work:

Example of an HTML page ⤵️

![Ferrum HTML page](/assets/images/ferrum-page-html.png)

Clicking the *"View as PDF"* link would open a link as PDF ⤵️

![Ferrum page turned into PDF](/assets/images/ferrum-page-pdf.png)

### Install and use [Gem Ferrum](https://github.com/rubycdp/ferrum)

Install the gem:

```ruby
# Gemfile
gem "ferrum"
```

Add a route:

```ruby
# config/routes.rb
get 'home/index'
```

Add an HTML page.

You can add a `link_to` render the page as PDF.

Notice I add a class `.no-print`, so that the link does not get displayed in `print` media type.

```html
<!-- app/views/home/index.html.erb -->
<h1>Home#index</h1>
<p>Find me in app/views/home/index.html.erb</p>
<div class="no-print">
  <%= link_to "View as PDF", home_index_path(format: :pdf) %>
</div>
```

Add `.no-print ` CSS class to elements that should not be printable:

```css
/* app/assets/stylesheets/application.css */
@media print {
  .no-print {
    display: none !important;
  }
}

/* other css classes you might want to add */
@media print {
  body {
    -webkit-print-color-adjust: exact;
    background: #fff;
    background-color: #fff;
    float: none;
    display: block;
  }
  .no_margin {
    padding-left: 0px !important;
  }
  .no-print {
    display: none !important;
  }
  .printer-preview-content,
  .printer-preview-content_landscape {
    max-width: 100% !important;
    width: 100% !important;
    height: auto !important;
    padding: 0 !important;
    margin: 0 !important;
  }
  .cover_div {
    display: table;
  }
}
```

Finally, use Ferrum to navigate to an internal or external URL and display it as PDF:

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.pdf do
        handle_pdf_format
      end
    end
  end

  private

  def handle_pdf_format
    filename = controller_name
    tmp = Tempfile.new("pdf-chrome-#{filename}")
    browser = Ferrum::Browser.new
    # browser.go_to("http://localhost:3000/home/index")
    browser.go_to(home_index_url)
    # browser.go_to("https://google.com")
    # click on "Accept all"
    # browser.at_css(".QS5gu.sy4vM").click
    sleep(0.3)
    browser.pdf(
      path: tmp.path,
      format: "A4".to_sym,
      landscape: false,
      # margin: {top: 36, right: 36, bottom: 36, left: 36},
      # preferCSSPageSize: true,
      # printBackground: true
    )
    browser.quit
    pdf_data = File.read(tmp.path)
    pdf_filename = "#{filename}.pdf"
    send_data(pdf_data,
              filename: pdf_filename,
              type: "application/pdf",
              disposition: "inline")
  ensure
    tmp.close
    tmp.unlink
  end
end
```

It works well for publicly accessible URLs, however it is not so straightforwar for links that require `current_user` authentication. I've asked a question here [https://github.com/rubycdp/ferrum/issues/423
](https://github.com/rubycdp/ferrum/issues/423) and am hoping for an easy enough solution 🤠
