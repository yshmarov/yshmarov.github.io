---
layout: post
title: API pagination with Pagy
author: Yaroslav Shmarov
tags: ruby-on-rails rails-api pagination
thumbnail: /assets/thumbnails/api.png
---

If you don't paginate GET LIST data in your API, most likely you will be giving your API consumers too much data, and adding too much load on your API.

Whenever a user can have more than ±50 records in a list, you must add pagination to your API. It's not that hard!

Example API GET request that contains pagination parameters:

```sh
curl -X 'GET' 'http://localhost:3000/api/v1/posts?page=2'
```

Response (current page is `2`):

```json
{
  "pagination": {
    "prev_url": "/api/v1/posts?page=1",
    "next_url": "/api/v1/posts?page=3",
    "count": 4,
    "page": 2,
    "next": 3
  },
  "data": [
    {"id": 1, "title": "first post"},
    {"id": 2, "title": "second post"}
  ]
}
```

Without pagination, our default API response would look like this:

```yaml
[
  {"id": 1, "title": "first post"},
  {"id": 2, "title": "second post"}
]
```

To add pagination parameters, we will use Pagy and update our jbuilder file.

```shell
bundle add pagy
```

Enable `pagy_metadata()` method, rescue from `Pagy::OverflowError`:

```ruby
# config/initializers/pagy.rb
require 'pagy/extras/metadata'
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :empty_page
```

Add pagination, include `pagy_metadata(@pagy)`:

```ruby
# app/controllers/api/v1/posts_controller.rb
  include Pagy::Backend
  def index
    items_per_page = 12
    user_posts = current_user.posts.all
    @pagy, @posts = pagy(user_posts, items: items_per_page)
    @pagination = pagy_metadata(@pagy)
  end
```

Rendering most important `pagy_metadata` within the json response:

```ruby
# app/views/api/v1/posts/index.json.jbuilder
json.pagination do
  json.extract! @pagination, :prev_url, :next_url, :count, :page, :next
end
# json.links do
#   json.prev @pagination[:prev_url]
#   json.next @pagination[:next_url]
# end
json.data do
  json.array! @posts, partial: "api/v1/posts/post", as: :post
end
```

Add pagination to your OpenAPI yaml file:

```diff
paths:
  /api/v1/posts:
    get:
+      parameters:
+        - in: query
+          name: page
+          schema:
+            type: integer
+            minimum: 1
+          description: Page number
      responses:
        '200':
```

Now, if you have followed me so far, you can make paganated API requests in your Swagger UI:

![api-pagination-openapi-swagger](/assets/images/api-pagination-openapi-swagger.png)

That's it!
