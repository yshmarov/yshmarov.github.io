---
layout: post
title: Devise Masquerade (Login as) with Avo
author: Yaroslav Shmarov
tags: avo impersonation
---

### Basic [devise masquerade](https://github.com/oivoodoo/devise_masquerade) (Login as)

```ruby
# Gemfile
gem "devise"
gem "devise_masquerade"
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
    before_action :authenticate_user!
    before_action :masquerade_user!
end
```

```ruby
# config/routes.rb
devise_for :users, controllers: {
  masquerades: "users/masquerades"
}
```

```ruby
# app/controllers/users/masquerades_controller.rb
class Users::MasqueradesController < Devise::MasqueradesController
  before_action :authorize_admin, except: :back

  protected

  def authorize_admin
    redirect_to root_path unless current_user.admin?
  end

  def after_back_masquerade_path_for(_resource)
    # your admin path
    Avo.configuration.root_path
  end
end
```

Admin UI: links to log in as a user

```ruby
User.all.each do |user|
  link_to "Login as", masquerade_path(user)
end
```

App UI: link to stop imperosnating

```ruby
# app/views/application.html.erb
<% if user_masquerade? %>
  <%= link_to t("devise.masquerade.back"), back_masquerade_path(current_user) %>
<% end %>
```

### Avo

You can't use `masquerade_path(User.last)` from Avo. So I had to create a helper:

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper

  def avo_masquerade_path(resource, *args)
    scope = Devise::Mapping.find_scope!(resource)

    opts = args.shift || {}
    opts[:masqueraded_resource_class] = resource.class.name

    opts[Devise.masquerade_param] = resource.masquerade_key

    Rails.application.routes.url_helpers.send(:"#{scope}_masquerade_index_path", opts, *args)
  end
end
```

Use it in Avo Admin UI:

```ruby
# app/avo/resources/user.rb
class Avo::Resources::User < Avo::BaseResource
  def fields
    field :login_as, as: :text, as_html: true do
      unless record.id == current_user.id
        link_to "Login as", helpers.avo_masquerade_path(record)
      end
    end
  end
end
```

# Avo canon approach

After [highlighting this issue in Avo discord](https://discord.com/channels/740892036978442260/1125160641569771550/1380485383778730074), Paul came up with a solution:

```
curl -o config/initializers/devise_masquerade_engine_patch.rb https://gist.githubusercontent.com/Paul-Bob/9f86cac656c1f5464ad9d423258538c8/raw/8c7dc52e963792ef6e8bf24e57cbe61bd40fb1c5/devise_masquerade_engine_patch.rb
```

```ruby
# config/initializers/devise_masquerade_engine_patch.rb

# Patch for DeviseMasquerade::Controllers::UrlHelpers
#
# Problem:
# - Devise Masquerade defines `_masquerade_index_path` helpers dynamically based on scope.
# - These helpers are only registered in the main application's routes.
# - When called from within an engine (e.g. Avo), these helpers may not be found, raising errors.
#
# Solution:
# - This patch intercepts missing `_masquerade_index_path` method calls.
# - If missing, it forwards them to the main application's route helpers.
# - This ensures compatibility with engines that rely on these routes indirectly.

module DeviseMasquerade
  module Controllers
    module UrlHelpers
      def method_missing(method_name, *args, &block)
        if method_name.to_s.end_with?("_masquerade_index_path")
          ::Rails.application.routes.url_helpers.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        if method_name.to_s.end_with?("_masquerade_index_path")
          ::Rails.application.routes.url_helpers.respond_to?(method_name)
        else
          super
        end
      end
    end
  end
end
```

```diff
# app/avo/resources/user.rb
class Avo::Resources::User < Avo::BaseResource
  def fields
    field :login_as, as: :text, as_html: true do
      unless record.id == current_user.id
-          link_to "Login as", helpers.avo_masquerade_path(record)
+          link_to "Login as", masquerade_path(record)
      end
    end
  end
end
```

That's it!

Next, see how User impersonation works in [Moneygun app bolierplate](https://github.com/yshmarov/moneygun)
