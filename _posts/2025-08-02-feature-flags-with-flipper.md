---
layout: post
title: "Feature Flags and A/B testing with gem flipper"
author: Yaroslav Shmarov
tags: rails feature-flags
thumbnail: /assets/thumbnails/rails-logo.png
---

3/4 of the last companies I worked with used [gem Flipper](https://www.flippercloud.io) for feature flags.

![flipper ui](assets/images/flipper-ui.png)

I also [added it](https://github.com/yshmarov/moneygun/pull/292) as a default into [my SaaS boilerplate](https://github.com/yshmarov/moneygun/pull/292).

Quick setup guide:

```sh

bundle add flipper-active_record
bundle add flipper-ui
bin/rails g flipper:setup
rails db:migrate
```

```ruby
# config/routes.rb
authenticate :user, ->(user) { user.admin? || Rails.env.development? } do
  mount Flipper::UI.app(Flipper) => "/feature_flags"
end
```

```ruby
# config/initializers/flipper.rb

# Add User and Organization "actors"
Flipper.register(:users) { |actor| actor.value.start_with?("User:") }
Flipper.register(:organizations) { |actor| actor.value.start_with?("Organization:") }

# Clean up flipper UI
Flipper::UI.configure do |config|
  config.fun = false
  config.cloud_recommendation = false
  config.show_feature_description_in_list = true
end
```

Usage

```ruby
Flipper[:search].enable
Flipper[:search].enabled?
Flipper[:search].disable

Flipper.enable(:search, User.first)
Flipper.enabled?(:search, current_user)
Flipper[:search].enabled?(current_user)

Flipper.enabled?(:search, Current.organization)
```
