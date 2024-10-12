---
layout: post
title: Hotwire Native iOS Path Configuration via API
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/turbo.png
---

With Hotwire Native you want to outsource as much logic as possible to your Web app.

Making changes in the Web app is easy.

Making changes in a Native app requires an additional release-review.

The hotwire native demo app has a `path-configuration.json` file that controls some navigation patterns.

Let's deliver this file via API from our Web app!

To do this, add a `server` url to your pathConfiguration:

```diff
# ios/SceneController
private lazy var pathConfiguration = PathConfiguration(sources: [
    .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
+    .server(rootURL.appending(path: "v1/turbo/ios/path_configuration.json"))
])
```

The server source takes precedence over the file source.

If the server source is not accessible, the app will fall back to the file source.

Add a corresponding route in your Rails app:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :v1 do
    namespace :turbo do
      namespace :ios do
        resource :path_configuration, only: [:show]
      end
    end
  end
end
```

Finally render the JSON in your controller action.

Be sure that this URL is accessible without restrictions like `authenticate_user!`.

```ruby
# app/controllers/v1/turbo/ios/path_configurations_controller.rb
# http://localhost:3000/v1/turbo/ios/path_configuration.json
class V1::Turbo::Ios::PathConfigurationsController < ApplicationController
  # skip_before_action :authenticate_user!

  def show
    render json: {
      "rules": [
        {
          "patterns": [
            "/new$",
            "/edit$",
          ],
          "properties": {
            "context": "modal"
          }
        },
        {
          "patterns": [
            "^/users/edit$"
          ],
          "properties": {
            "context": "default"
          }
        }
      ]
    }
  end
end
```

[Subscribe to SupeRails.com](https://superails.com/pricing) for more Hotwire Native content!

That's it for now!
