---
layout: post
title: "Generate and display OpenGraph images"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails SEO meta-tags ferrum
thumbnail: /assets/thumbnails/url.png
---

[This post](https://www.reddit.com/r/rails/comments/1eiyect/what_do_you_use_for_generating_opengraph_images/) inspired me to write this article:

![og-auto-q-reddit](/assets/images/og-auto-q-reddit.png)

Previously I wrote about setting [Meta tags in a Rails app]({% post_url 2021-10-28-meta-tags-without-a-gem %}). Meta tags really make your web pages more "shareable".

But generating OpenGraph images can be a challenge. There are many businesses built around this. For example:

- [Tinyzap](https://tinyzap.com)
- [htmlcsstoimage](https://htmlcsstoimage.com/demo)
- [Vercel og image generator](https://vercel.com/docs/functions/og-image-generation)
- [Thumbsmith](https://thumbsmith.com/)
- [Jekyll OG generator](https://x.com/igor_alexandrov/status/1754479670953676963)
- [ogimage.org](https://x.com/illyism/status/1763843779239329842)

But you are a great developer! You don't need to pay for a tool that you can just build, right?

Let's build an OpenGraph image generator!

We could use [Rmagick]({% post_url 2022-10-03-rmagick-activestorage %}) to draw images with their API.

But maybe an easier approach would be to generate some HTML, open it in a browser, and take a screenshot.

For this we will use [Gem Ferrum]({% post_url 2024-01-27-gem-ferrum-generate-pdf %}) that is a headless Chrome API.

There are a few levels of coolness/complexity for taking screenshots of an url:

- Level 1.1. Take a screenshot of an URL
- ~~Level 1.2. Take a screenshot of an URL selector (id/class)~~
- Level 2.1. Take a screenshot of an URL with a **dedicated** template
- ~~Level 2.2. Visit web page, parse the meta `%i[title, description, logo, date]` & autocomplete your **generic** template~~

### Level 1.1. Take a screenshot of an URL

Example of final result - a screenshot of a page:

![og-screenshot](/assets/images/https-superails-com-posts-rails-160-meta-tags-open-graph-seo-social-sharing-previews-playlist-build-an-opengraph-automation-tool.png)

We will leverage the [Ferrum Screenshot API](https://github.com/rubycdp/ferrum#screenshots):

```ruby
# rails g job UrlToImage
# url = "https://superails.com/posts/181-search-and-autocomplete-french-company-information"
# UrlToImageJob.perform_now(url)
class UrlToImageJob < ApplicationJob
  queue_as :default

  def perform(url)
    browser = Ferrum::Browser.new
    browser.resize(width: 1200, height: 630)
    browser.goto(url)
    # browser.screenshot(path: "tmp/screenshots/#{url.parameterize}.jpg")
    # browser.screenshot(path: "tmp/screenshots/#{url.parameterize}.jpg", quality: 40, format: "jpg")
    # browser.screenshot(path: "tmp/screenshots/#{url.parameterize}.jpg", quality: 40, format: "jpg", full: true)
    # sleep 0.5
    # browser.screenshot(path: "app/assets/images/opengraph/#{url.parameterize}.jpg", quality: 40, format: "jpg", selector: "main")
    browser.screenshot(path: "app/assets/images/opengraph/#{url.parameterize}.jpg", quality: 40, format: 'jpg')
  ensure
    browser.quit
  end
end
```

ℹ️ Generating JPEG can be faster than PNG.

And here's a helper to access the generated image based on the current URL:

```ruby
# app/helpers/application_helper.rb
  def meta_opengraph_image_asset_path
    base_url = Rails.application.config_for(:settings).dig(:site, :url, :production)
    image_name = [base_url, request.path].join.parameterize
    full_path = "opengraph/#{image_name}.png"
    helpers.image_url(full_path)
  rescue StandardError
    image_url('logo.png')
  end
```

Display the image in meta tags

```ruby
# posts/show.html.erb
<%= content_for :head do %>
  <%= tag.meta(property: 'og:image', content: meta_opengraph_image_asset_path) %>
  <%= tag.meta(property: 'twitter:card', content: "summary_large_image") %>
<% end %>
```

This way we store the image in our assets. It is for you to decide a better way to **deliver** these images to production.

### Level 2.1. Take a screenshot of an URL with a **dedicated template**

Example of final result:

![og-ferrum-with-layout](/assets/images/og-ferrum-with-layout.png)

Instead of visiting an URL, we can just render plain HTML in Ferrum and take a screenshot of it:

```ruby
# https://github.com/rubycdp/ferrum/blob/main/lib/ferrum/frame.rb#L109
browser = Ferrum::Browser.new
browser.resize(width: 1200, height: 630)
frame = browser.frames.first
frame.body
# => "<html><head></head><body></body></html>"
frame.content = "<html><head></head><body>Voila!</body></html>"
frame.body
# => "<html><head></head><body>Voila!</body></html>"
```

Now we can create a layout and template for our open graph images!

A minimalistic CSS-only layout:

```html
<!-- app/views/layouts/minimal.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>Og</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
  </head>
  <body style="background: linear-gradient(to right, #fdf497, #fdf497, #fd5949, #d6249f, #285AEB); display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0;">
    <div style="transform: rotate(4deg);">
      <%= yield %>
    </div>
  </body>
</html>
```

A template for generating post images:

```html
<!-- app/views/posts/og.html.erb -->
<div style="border: 1px solid #ddd; padding: 2rem; background-color: #fff; border-radius: 15px; margin: 2rem; display: flex; flex-direction: column; align-items: center; gap: 1rem; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); max-width: 600px; margin: auto;">
  <div style="height: 80px; margin-bottom: 1rem;">
    <img src="http://localhost:3000/logolong.png" height="80">
    <%#= image_tag asset_url('logo.png'), style: 'width: 100%; height: 80px;' %>
  </div>
  <div style="word-break: break-word; font-weight: bold; font-size: 2rem; text-align: center; color: #333;">
    <%= @post.title %>
  </div>
  <div style="width: 100%; display: flex; justify-content: center; margin-bottom: 1rem;">
    <%= image_tag post_image_path(@post), style: 'max-width: 100%; height: auto; border-radius: 10px;' %>
  </div>
  <div style="font-size: 0.8rem; color: #777; font-style: italic; font-weight: bold;">
    <%= @post.published_at.strftime('%B %d, %Y') %>
  </div>
</div>
```

Finally, here's the job to generate a screenshot from the above HMTL:

```ruby
# post = Post.first
# PostToImageJob.perform_now(post)
class PostToImageJob < ApplicationJob
  queue_as :default

  def perform(post)
    @post = post
    html = ApplicationController.render(
      template: 'posts/og',
      layout: 'minimal',
      assigns: { post: @post })

    browser = Ferrum::Browser.new
    browser.resize(width: 1200, height: 630)
    frame = browser.frames.first
    # frame.content = "<html><head></head><body>Voila!</body></html>"
    frame.content = html

    # ensure all images are loaded!
    browser.network.wait_for_idle
    # double check if all images are loaded!!
    browser.evaluate(%(
      function waitForImages() {
        return new Promise((resolve) => {
          const images = document.querySelectorAll('img');
          let loaded = 0;
          images.forEach((img) => {
            if (img.complete) {
              loaded += 1;
            } else {
              img.onload = () => {
                loaded += 1;
                if (loaded === images.length) {
                  resolve();
                }
              };
            }
          });
          if (loaded === images.length) {
            resolve();
          }
        });
      }
      waitForImages();
    ))
    # tripple check if all images are loaded!!!
    sleep 1

    browser.screenshot(path: Rails.root.join('tmp', 'screenshot.png'))
    browser.screenshot(path: "app/assets/images/opengraph/posts/#{post.id}.png", quality: 40, format: 'jpg')
  ensure
    browser.quit
  end
end
```

That's it! 🤠

Related resoures:
- [How to generate OG links preview like Dev.to (for free) with Rails 7](https://dev.to/matiascarpintini/how-to-generate-og-links-preview-like-devto-for-free-with-rails-7-57b2)
- [how-we-built-unique-social-preview-images-for-pika](https://goodenough.us/blog/2024-02-12-how-we-built-unique-social-preview-images-for-pika/)
- [Github: framework-building-open-graph-images](https://github.blog/2021-06-22-framework-building-open-graph-images/)
- [agneym/generate-og-image](https://github.com/agneym/generate-og-image)
- [Automating Jekyll card generation with ruby's Ferrum gem](https://jay.gooby.org/2022/05/11/automating-jekyll-card-generation-with-ruby-ferrum)
