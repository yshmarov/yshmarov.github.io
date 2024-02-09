---
layout: post
title: API Tracking and Usage limiting
author: Yaroslav Shmarov
tags: ruby-on-rails rails-api
thumbnail: /assets/thumbnails/api.png
youtube_id: GNRkG-Rc2IE
---

If you don't **limit** your API usage, bad users can DDOS your server.

If you don't **track** API usage, how do you know if it is even used?

Apps like Twitter and Shopify have daily or monthly (30-day) API usage limits:
* [Twitter API rate limits](https://developer.twitter.com/en/docs/twitter-api/rate-limits)
* [Shopify REST Admin API rate limits](https://shopify.dev/docs/api/usage/rate-limits#rest-admin-api-rate-limits)

In this tutorial we will track API usage per user and add a 30-day max limit of API requests per user.

Example of API request being blocked by `status 429 Too Many Requests`:

![api-request-limit-exceeded](/assets/images/api-request-limit-exceeded.png)

`ApiRequest` model will store the usage data:

```sh
rails g model ApiRequest user:references path method
```

On the user model:
* set a max limit of requests per month
* count requests within the last 30 days
* check if the limit is exceeded

```ruby
# app/models/user.rb
class User < ApplicationRecord
  ...

  has_many :api_requests

  MAX_API_REQUESTS_PER_30_DAYS = 10_000

  def api_requests_within_last_30_days
    api_requests.where("created_at > ?", 30.days.ago).count
  end

  def api_request_limit_exceeded?
    api_requests_within_last_30_days >= MAX_API_REQUESTS_PER_30_DAYS
  end
end
```

In the base API controller, log API requests with `log_api_request` and check limit:

```ruby
# app/controllers/api/v1/authenticated_controller.rb
  before_action :check_api_limit
  before_action :log_api_request

  ...

  private

  ...

  def log_api_request
    current_user.api_requests.create!(path: request.path, method: request.method)
    # in the response header, include remaining api request count
    response.headers['X-Superails-User-Api-Call-Limit'] = "#{current_user.api_requests_within_last_30_days.to_s}/#{User::MAX_API_REQUESTS_PER_30_DAYS.to_s}"
  end

  def check_api_limit
    if current_user.api_request_limit_exceeded?
      render json: { message: "API request limit exceeded" }, status: :too_many_requests
    end
  end
```

Now when a user tries to make an API request, we will first check if the user has exceeded the limit.

If the limit is not exceeded, the request is performed and data about it is stored in the ApiRequest model.

Shopify also includes a [Rate limits header](https://shopify.dev/docs/api/usage/rate-limits#rate-limits-header). With `response.headers['X-Superails-User-Api-Call-Limit']` we are doing the same!

To display request headers in a response from a curl request, you can include the `-v` option: `curl -v -X GET localhost:3000/api/v1/home/index.json -H "Authorization: Bearer MySecretToken"`.

![api-curl-response-with-headers](/assets/images/api-curl-response-with-headers.png)

That's it!
