---
layout: post
title: Introduction to Nokogiri. Extract core website data
author: Yaroslav Shmarov
tags: nokogiri
thumbnail: /assets/thumbnails/ruby.png
---

Recently I was thinking of building a **directory website** that would list other websites/apps under different categories. 

I would need to display some core data for each website, like:
- `title`
- `description`
- logo (`favicon`)
- screenshot/`opengraph image`

[Gem Nokogiri](https://github.com/sparklemotion/nokogiri) lets us easily parse HTML. It is one of the foundational Ruby gems, that many other gems rely on.

Here's how we can parse any URL and extract code data with Nokogiri:

```ruby
require "nokogiri"
require "open-uri"
require "uri"

class UrlCrawlerJob < ApplicationJob
  queue_as :default

  def perform(url)
    html = URI.open(url)

    # Parse the HTML with Nokogiri
    doc = Nokogiri::HTML(html)

    # Extract the page title
    page_title = doc.at("title")&.text

    # Extract the favicon URL
    favicon = doc.at('link[rel="icon"]')
    favicon_url = favicon ? URI.join(url, favicon["href"]).to_s : nil

    # Extract the meta description
    meta_description = doc.at('meta[name="description"]')&.[]("content")

    # Extract the OpenGraph image
    og_image = doc.at('meta[property="og:image"]')&.[]("content")
    og_image_url = og_image ? URI.join(url, og_image).to_s : nil

    {
      page_title:,
      favicon_url:,
      meta_description:,
      og_image_url:
    }
  end
end
```

### Store, Retrieve data

Let's assume you want to have a model that has a url and stores the extracted data.

I prefer to store this kind of data in `json` instead of creating new attributes each time.

```shell
rails g model website url payload:json
```

Parse an url and store the extracted data:

```ruby
url = "http://superails.com/"
website = Website.create(url:)
payload = UrlCrawlerJob.perform_now(website.url)
website.update(payload:)
```

Now you can get values with digging the json/hash:

```ruby
website.payload["page_title"]
=> "SupeRails"
```

You can make it easier with `OpenStruct`:

```ruby
# app/models/website.rb
require "ostruct"

def payload_data
  OpenStruct.new payload
end
# payload_data.favicon
# website.payload_data.page_title

# search anywhere in the payload:
# Listing.ransack(payload_cont: "superails").result
ransacker :payload do
  Arel.sql("payload")
end
```

That's it!
