---
layout: post
title: Image scraping with Rails. Save image from URL to ActiveStorage
author: Yaroslav Shmarov
tags: ruby rails active-storage
thumbnail: /assets/thumbnails/placeholder-image.png
---

Sometimes we have an image url, that we want to "download" and store directly in our app's storage.

Usecase examples:
- scrape images from reddit or imgur?
- User signs up with an oAuth provider, we get an image_url from the oAuth params
- Import Youtube videos via API and store thumbnail locally from thumbnail_url

Install ActiveStorage:

```ruby
bin/rails active_storage:install
bin/rails db:migrate
bundle add image_processing
```

Attach `cover_image` to `Post` via `ActiveStorage`:

```ruby
# app/models/post.rb
  has_one_attached :cover_image
```

Job that attaches an image from `image_url` to a `post`:

```ruby
require 'open-uri'

class StoreCoverImageJob < ApplicationJob
  queue_as :default

  PERMIT_IMAGE_FORMAT = %w[png jpg jpeg].freeze

  def perform(post, image_url)
    valid_image_format = get_content_type(image_url)
    return unless valid_image_format

    uri = URI.parse(image_url)
    image = uri.open
    image_name = File.basename(image_url)
    post.cover_image.attach(io: image, filename: image_name, content_type: valid_image_format)
  end

  private

  def get_content_type(image_url)
    ext_name = File.extname(image_url).delete('.')
    return unless PERMIT_IMAGE_FORMAT.include?(ext_name)

    "image/#{ext_name}"
  end
end
```

Try it in your `rails console`:

```ruby
post = Post.first
post.cover_image.attached? #=> false
image_url = "https://i.ytimg.com/vi/Ubrr9mqE94o/maxresdefault.jpg"
StoreCoverImageJob.perform_now(post, image_url)
post.cover_image.attached? #=> true
```

### Testing

Test `StoreCoverImageJob`:

```ruby
# test/jobs/youtube/store_cover_image_job_test.rb
require 'test_helper'

class StoreCoverImageJobTest < ActiveJob::TestCase
  test 'attach cover image' do
    post = posts(:one)
    assert_not post.cover_image.attached?

    StoreCoverImageJob.perform_now

    assert post.reload.cover_image.attached?
  end
end
```

Test `has_one_attached :cover_image`

```ruby
# test/models/post_cover_image_test.rb
require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test 'cover_image is attached to post' do
    post = Post.new
    post.cover_image.attach(io: Rails.root.join('test/fixtures/files/image.jpg').open,
                            filename: 'image.jpg',
                            content_type: 'image/jpeg')

    assert post.valid?
    assert post.cover_image.attached?
    assert_equal 'image.jpg', post.cover_image.filename.to_s
    assert_equal 'image/jpeg', post.cover_image.content_type
  end
end
```

That's it!
