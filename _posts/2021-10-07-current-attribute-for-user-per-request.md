---
layout: post
title: "Current attribute support to set Current.user per request"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails devise
thumbnail: /assets/thumbnails/devise.png
---

#app/controllers/application_controller.rb
```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user, if: :user_signed_in?

  private

  def set_current_user
    Current.user = current_user
  end
end
```

#app/models/current.rb
```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
```

* Now you can get current_user through Current.user in a view or get current_user in a model.

#static_pages/landing_page.html.erb
```ruby
<%= Current.user.username %>
```

#app/models/post.rb
```ruby
class Post < ApplicationRecord
  belongs_to :user, default: -> { Current.user }

  validates :title, presence: true
end
```