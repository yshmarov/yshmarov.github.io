---
layout: post
title: Testing Rails cache
author: Yaroslav Shmarov
tags: caching testing
thumbnail: /assets/thumbnails/rails-logo.png
---

In one of my apps I have a pricing page. However the prices are stored only inside my Stripe account, not inside my app database.

So whenever a user visits the `/pricing` page, I would make an API request to Stripe to get the prices.

This is BAD: these API requests increase the page load time, and moreover you can hit an API limit.

Getting static content via an API request is a perfect example of something you can **CACHE**.

Caching = storing temporarily with an expiry date.

Cache data with `Rails.cache.write`:

```ruby
# Rails.cache.write(key, value, expires_in: 24.hours)
price.each do |price|
  Rails.cache.write("price-#{price.id}", [price.name, price.amount, price.interval].join(';'), expires_in: 24.hours)
end
```

Read stored data `Rails.cache.read`:

```ruby
Rails.cache.read("price-7484845785247")
# => ["price-7484845785247", #<ActiveSupport::Cache::Entry:0x0000000107be9170 @value="Premium;300;month", @version=nil, @created_at=0.0, @expires_in=1700163180.17973>]
```

Example of testing a `CacheStripePricingJob`:

```ruby
require "test_helper"

class CacheStripePricingJobTest < ActiveJob::TestCase
  test "perform" do
    # Rails.cache.clear

    original_cache_store = Rails.cache
    # MIMIC A NEW CACHE INSTANCE
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    # Rails.cache
    # EMPTY CACHE LOOKS LIKE THIS:
    # => #<ActiveSupport::Cache::MemoryStore entries=0, size=0, options={:compress=>false, :compress_threshold=>1024}>

    perform_enqueued_jobs

    assert_performed_jobs 1

    # cache_data.first
    # ["price-7484845785247", #<ActiveSupport::Cache::Entry:0x0000000107be9170 @value="Premium;300;month", @version=nil, @created_at=0.0, @expires_in=1700163180.17973>]

    cache_data = Rails.cache.instance_variable_get(:@data)
    assert_not_nil cache_data

    value = "Premium;300;month"
    assert cache_data.values.map(&:value).any?(value)

    key = "price-7484845785247"
    assert cache_data.keys.any?(key)

    cache_data.first
    assert_equal Rails.cache.read(key), value

    Rails.cache = original_cache_store
  end
end
```

That's it! I might add more details about Rails caching inside this blogpost in the future.
