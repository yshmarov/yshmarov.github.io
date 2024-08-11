---
layout: post
title: Use Gem Rack-attack with Devise and Rails 7
author: Yaroslav Shmarov
tags: rack-attack rate-limiting
thumbnail: /assets/thumbnails/lock.png
---

Sooner or later, somebody will try to DDOS your app.

To decrease the gravity of attacks, you can use [**gem rack-attack**](https://github.com/rack/rack-attack).

### 1. Install and use Rack Attack

```sh
bundle add rack-attack
```

```diff
# config/application.rb
module Myapp
  class Application < Rails::Application
    config.load_defaults 7.0
+    config.middleware.use Rack::Attack
  end
end
```

Simple rack-attack initializer setup:
* limit request count by an IP address
* limit login requests to devise sign_up/sign_in pages

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("req/ip", limit: 1000, period: 5.minutes) do |req|
  unless req.path.start_with?("/assets")
    Rails.logger.error("Rack::Attack Too many requests from IP: #{req.ip}")
    req.ip
  end
end

Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == "/users/sign_in" && req.post?
end

Rack::Attack.throttle("logins/email", limit: 5, period: 20.seconds) do |req|
  if req.path == "/users/sign_in" && req.post?
    req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
  end
end

Rack::Attack.throttle("users/sign_up", limit: 3, period: 15.minutes) do |req|
  req.ip if req.path == "/users" && req.post?
end
```

### 2. Test how rack-attack works on localhost

Decrease the request limits for your testing purposes:

```diff
-Rack::Attack.throttle("req/ip", limit: 1000, period: 5.minutes) do |req|
+Rack::Attack.throttle("req/ip", limit: 8, period: 5.minutes) do |req|
```

While running `rails s` in one console tab, open another console tab and run > 8 CURL requests to your app:

```sh
for i in {1..10}; do curl -X GET http://localhost:3000/users/sign_in;
done
```

In your `rails s` logs you should get `Rack::Attack Too many requests from IP: 127.0.0.1`:

![Rack::Attack Too many requests from IP](/assets/images/rack-attack-too-many-requests.png)

P.S. When installing the gem based on the readme, I had issues. [This stackoverflow question](https://stackoverflow.com/questions/64923601/rack-attack-throttling) had all the answers.

That's it! 🤠
