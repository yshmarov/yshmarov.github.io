---
layout: post
title: Rails CRUD API requests with cURL
author: Yaroslav Shmarov
tags: ruby-on-rails rails-api curl
thumbnail: /assets/thumbnails/api.png
---

cURL let's you make HTTP requests from the command-line/terminal.

You can make API CRUD requests to a Rails controller via cURL.

Let's create a `Post` scaffold and make some CRUD requests:

```ruby
rails g scaffold Post title:string body:text published:boolean published_at:datetime
```

#### READ

**index**

```sh
curl -X GET http://localhost:3000/posts.json
```

**show**

```sh
curl -X GET http://localhost:3000/posts/1.json
```

#### CREATE, UPDATE, DELETE

If you try performing `Create`, `Update`, `Delete` actions, you will get a `ActionController::InvalidAuthenticityToken` error due to [RequestForgeryProtection](https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html).

Add `protect_from_forgery with: :null_session` to your controller to enable these requests:

```ruby
# app/controllers/posts_controller.rb
  # skip_before_action :verify_authenticity_token
  # skip_before_action :authenticate_user!
  protect_from_forgery with: :null_session
```

Important: now anybody on the internet will be able to make changes to your database. In a real environment, you would want to [add an authentication layer to your cURL requests]({% post_url 2023-04-10-rails-api-bearer-authentication %}).

**create**

```sh
curl -X POST -H "Content-Type: application/json" -d '{"post": {"title": "Example Title", "body": "Example Body", "published": true, "published_at": "2023-04-12T12:34:58Z"}}' http://localhost:3000/posts.json
```

**update**

```sh
curl -X PATCH -H "Content-Type: application/json" -d '{"post": {"title": "Updated Title"}}' http://localhost:3000/posts/1.json
```

**destroy**

```sh
curl -X DELETE http://localhost:3000/posts/1.json
```
