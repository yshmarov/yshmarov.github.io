---
layout: post
title: Generate PDF and PNG with Ferrum (headless Chrome API)
author: Yaroslav Shmarov
tags: ruby-on-rails ferrum pdf html-to-pdf headless-chrome
thumbnail: /assets/thumbnails/pdf.png
---

Usually I would use an HTML-to-PDF library to to generate and display a PDF of a web page.

**An absolutely different**, alternative way to view or download a page as `PDF`/`PNG (screenshot)` would be via a **headless browser API**.

You could use [gem Grover](https://github.com/Studiosity/grover) that uses a Node.js API for Chrome named ["Puppeteer"](https://github.com/puppeteer/puppeteer). However Grover/Puppeteer has a **NodeJS depencency** 👎🚩🚩🚩

[Gem Ferrum](https://github.com/rubycdp/ferrum) does the same, but **without** a NodeJS dependency! 🟢

As a browser API tool, Ferrum lets you open a headless chrome browser and perform different actions:
* visit web page
* HTTP authenticate
* find element by css/id
* click link
* take screenshot
* open as PDF

Yes, we can use Ferrum to open or save a file as PDF! Here's a basic flow:

When a user clicks on "View as PDF" link ⤵️

![Ferrum HTML page](/assets/images/ferrum-page-html.png)

Ferrum visits this page, opens it as PDF, and opens it as PDF in a new tab ⤵️

![Ferrum page turned into PDF](/assets/images/ferrum-page-pdf.png)

Or downloads it as PDF 📄

Or saves it as a screenshot 🖼️

Let's try to make it work

### 1. Generate a PDF from any URL and store the file in your apps **root folder**

Install the [gem Ferrum](https://github.com/rubycdp/ferrum):

```ruby
# terminal
# gem "ferrum"
bundle add ferrum
# create a job to generate PDFs
rails g job UrlToPdf
```

A basic job to visit an URL and save is as PDF:

```ruby
# ToPdfJob.perform_now("https://superails.com/posts")
class ToPdfJob < ApplicationJob
  queue_as :default

  def perform(url)
    browser = Ferrum::Browser.new
    browser.goto(url)
    sleep(0.3)
    browser.pdf(
                path: "#{url.parameterize}.pdf",
                landscape: false,
                format: :A4,
                preferCSSPageSize: false,
                printBackground: true)
    browser.quit
  end
end
```

### 2. **Download** or **Open** PDF in a new browser tab

Display users a `link_to` download or open the URL as PDF:

```ruby
link_to 'PDF', home_path(format: :pdf), target: :_blank
# link_to 'PDF', invoice_path(invoice, format: :pdf), target: :_blank
```

Handle the request in the controller

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.pdf do
        # url = "https://superails.com/posts"
        url = home_url
        pdf_data = ToPdfJob.perform_now(url)
        send_data(pdf_data,
                  filename: "#{url.parameterize}.pdf",
                  type: "application/pdf",
                  disposition: "inline") # open in browser
                  # disposition: "attachment") # default # download
      end
    end
  end
end
```

Finally, generate a "pdf string" with Ferrum:

```ruby
# ToPdfJob.perform_now("https://superails.com/posts")
class ToPdfJob < ApplicationJob
  queue_as :default

  def perform(url)
    tmp = Tempfile.new
    browser = Ferrum::Browser.new(headless: true,
      process_timeout: 30,
      timeout: 200,
      pending_connection_errors: true)
    browser.goto(url)
    sleep(0.3)
    browser.pdf(
                path: tmp.path,
                landscape: false,
                format: :A4,
                preferCSSPageSize: false,
                printBackground: true)
    File.read(tmp.path)
  ensure
    browser.quit
    tmp.close
    tmp.unlink
  end
end
```

ℹ️ we added `process_timeout: 30, timeout: 200, pending_connection_errors: true` and `sleep(0.3)` to try preventing this error: 

```ruby
  Ferrum::PendingConnectionsError (Request to http://localhost:3000/home/index reached server, but there are still pending connections: http://localhost:3000/home/index)
```

### ℹ️ `send_file` vs `send_data`

* Use `send_data` if you already did `File.read(path)`
* Use `send_file` and you **don't need** to do `File.read(path)`

### 3. PNG/screenshots

```diff
# ToImageJob
- browser.pdf
+ browser.screenshot(path: tmp.path, full: true, quality: 60, format: "png")
```

```ruby
# controller
  url = "https://superails.com"
  image_data = ToImageJob.perform(url)
  send_data image_data, type: "image/png", disposition: "attachment", filename: "#{url.parameterize}.png"
```

### 4. Store PDF/PNG with ActiveStorage

Generating documents "on the fly" can actually take some time (you spin up a browser each time), and can be expensive for popular pages. Instead, you can store the generated files.

Scenario: when an **Invoice** is created, generate a PDF/PNG and attach it to the record.

```ruby
# app/models/invoice.rb
  has_one_attached :document

  after_create_commit do
    self.generate_and_attach_pdf
  end

  def generate_and_attach_pdf
    browser = Ferrum::Browser.new(headless: true)
    browser.goto(Rails.application.routes.url_helpers.invoice_url(self))
    tmp = Tempfile.new

    # browser.pdf(path: tmp.path)
    browser.screenshot(path: tmp.path, full: true, quality: 60, format: "png")
    # browser.screenshot(path: tmp.path, full: true, quality: 60, format: "png", selector: "#invoice")

    self.document.attach(io: File.open(tmp), filename: "invoice_#{id}.png")

    browser.quit
    tmp.close
    tmp.unlink
  end
```

A download link:

```ruby
link_to "View", rails_blob_path(@invoice.document, disposition: "inline"), target: :_blank if @invoice.document.attached?
link_to "Download", rails_blob_path(@invoice.document, disposition: "attachment"), target: :_blank if @invoice.document.attached?
```

### 5. CSS Print OPTIONS

You can add CSS that will apply only to "Print/PDF" using `@media print`.

Add `.no-print ` CSS class to elements that should not be displayed in `print` media type:

```css
/* app/assets/stylesheets/application.css */
@media print {
  .no-print {
    display: none !important;
  }
}
```

Example:

```diff
<!-- app/views/home/index.html.erb -->
<h1>Home#index</h1>
<p>Find me in app/views/home/index.html.erb</p>
-<div>
+<div class="no-print">
  <%= link_to "View as PDF", home_index_path(format: :pdf) %>
</div>
```

Other css classes you might want to consider:

```css
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
  .printer-preview-content,
  .printer-preview-content_landscape {
    max-width: 100% !important;
    width: 100% !important;
    height: auto !important;
    padding: 0 !important;
    margin: 0 !important;
  }
}
```

### 6. Authentication

It works well for publicly accessible URLs, however it is not so straightforwar for links that require `current_user` authentication.

#### 6.1. Username-Password auth

I did not yet figure out how to sign in a devise user as you would do in tests with `sign_in(User.first)`. 

In this flow we:
1. create a user
2. visit the sign in form, fill it in
3. visit a user-only part of the app

```ruby
  user = User.create!(email: "foo@bar.com", password: "password", admin: true)

  browser = Ferrum::Browser.new
  browser.go_to("https://superails.com/users/sign_in")
  headless_sign_in(user)
  sleep(0.3)
  browser.go_to
  browser.go_to("https://superails.com/admin")

  private

  def headless_sign_in(user)
    email_input = browser.at_css('input[name="user[email]"]')
    email_input.focus.type(user.email)
    password_input = browser.at_css('input[name="user[password]"]')
    password_input.focus.type("password")
    login_button = browser.at_css('input[name="commit"]')
    login_button.click
  end
```

#### 6.2. HTTP Basic auth

My idea: make download path public (not require `current_user`), but restrict them with [HTTP basic authentication]({% post_url 2021-09-27-http-basic-authentication %}). Next, perform the authentication with the headless browser to access content.

```ruby
# app/controllers/export_controller.rb
class ExportController < ActionController::Base
  before_action :http_authenticate
  skip_before_action :http_authenticate, only: :report, if: -> { request.format.pdf? }

  def report
    respond_to do |format|
      format.html
      format.pdf do
        image_data = ToPdfJob.perform(export_report_url)
        send_data image_data, type: "image/png", disposition: "attachment", filename: "#{filename}.png"
      end
    end
  end

  private

  def http_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == Rails.application.credentials.dig(:http_basic_auth, :username) &&
        password == Rails.application.credentials.dig(:http_basic_auth, :password)
    end
  end
```

```yml
http_basic_auth:
  username: # generate something with SecureRandom.hex
  password: # generate something with SecureRandom.hex
```

```ruby
  browser = Ferrum::Browser.new
  browser.network.authorize(user: Rails.application.credentials.dig(:http_basic_auth, :username),
    password: Rails.application.credentials.dig(:http_basic_auth, :password)) { |req| req.continue }
  browser.go_to(url)
```

### 6.3.  Bearer token auth

If users of your app can use [Bearer token authentication]({% post_url 2023-04-10-rails-api-bearer-authentication %}) to access API endpoints in your app, you can add auth headers to the browser:

```ruby
# *This is not fully tested
  browser.headers.add({"Authorization" => "Bearer MyBearerToken123"})
  browser.headers.add({"accept" => "application/html"})
  browser.go_to(url)
```

### 7. Heroku 

To make Ferrum work in production, you need to install `google-chrome` in your production ENV.

For heroku, you can add google-chrome buildpack with the command:

```shell
heroku buildpacks:add heroku/google-chrome -a myappname
```

🚨 **IMPORTANT**: this buildpack has to be added **ABOVE** the ruby buildpack!

### 8. [Github CI](https://github.com/rubycdp/ferrum/blob/main/.github/workflows/tests.yml#L30)

```yml
    steps:
      - name: Setup Chrome
        uses: browser-actions/setup-chrome@latest
        with:
          chrome-version: stable
```

### 9. Other usecases

* [Automating Jekyll card generation with ruby's Ferrum gem](https://jay.gooby.org/2022/05/11/automating-jekyll-card-generation-with-ruby-ferrum)

That's it! I might be adding more to this article later.
