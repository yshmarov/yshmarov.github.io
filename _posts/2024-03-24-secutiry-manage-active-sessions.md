---
layout: post
title: "Manage active sessions in Rails 2024"
author: Yaroslav Shmarov
tags: security pentest
thumbnail: /assets/thumbnails/encryption-lock.png
---

Ok, so sometimes to enchance security of your application you will want to allow users to see all the devices/browsers they are logged in with. You would also provided a button to sign out of a device/browser.

Here's how you can do it:

### 1. Store current login (device/browser) info and ensure the current device/browser has not been logged out.

```ruby
rails g resource Login user:references device_id ip_address user_agent
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :logins, dependent: :destroy
end
```

```ruby
# app/models/login.rb
class Login < ApplicationRecord
  belongs_to :user
end
```

```ruby
# app/controllers/application_controller.rb
  include Users::LoginActivity

  # ensure this device has not been logged out
  before_action :validate_login, if: :current_user

  # this works with Devise
  # when logging a user in, register the current device
  def after_sign_in_path_for(resource_or_scope)
    set_login # this!
    root_path
  end
```

```ruby
# app/controllers/concerns/users/login_activity.rb
module Users
  module LoginActivity
    extend ActiveSupport::Concern

    # included do
    #   helper_method :set_login
    # end

    def set_login
      current_login = current_user.logins.where(device_id: device_id).first_or_create(ip_address: request.remote_ip, user_agent: request.user_agent, device_id: device_id)
      # current_login.touch
      # current_login.save
      session[:device_id] = device_id
      # cookies[:device_id] = device_id
    end

    def validate_login
      if Rails.env.test?
        # mock
        current_login = current_user.logins.create(device_id: "test_device_id")
      else
        current_login ||= current_user.logins.find_by(device_id: session[:device_id])
      end

      if current_login.nil?
        sign_out current_user

        flash[:notice] = 'Device not recognized'
        redirect_to new_user_session_path
      end
    end

    private

    def device_id
      Digest::SHA256.hexdigest("#{request.remote_ip}_#{request.user_agent}")
      # SecureRandom.hex
    end

  end
end
```

### 2. Views to see all logins of a user, log out of a select device/browser

```ruby
# config/routes.rb
  namespace :users do
    resources :logins, only: %i[index destroy]
  end
```

```ruby
# app/controllers/users/logins_controller.rb
class Users::LoginsController < Accounts::BaseController
  def index
    @logins = current_user.logins
  end

  def destroy
    @login = current_user.logins.find(params[:id])
    @login.destroy

    flash[:notice] = "You have been logged out of this device."
    redirect_to edit_user_registration_path
  end
end
```

```ruby
# app/views/logins/index.html.erb
<% @logins.order(updated_at: :desc).each do |login| %>
  <div>
    <i class="<%= device_type_icon(login.user_agent) %>"></i>

    <%= device_description(login.user_agent) %>

    Last login at:
    <%= login.updated_at %>

    IP address:
    <%= login.ip_address %>

    <% if login.device_id == session[:device_id] %>
      current session
    <% else %>
      <%= link_to 'Disconnect', users_login_path(login), method: :delete %>
    <% end %>

  </div>
<% end %>
```

ℹ️ [gem "device_detector"](https://github.com/podigee/device_detector) will help you decript `user_agent` info and make it user-friendly.

```ruby
module LoginsHelper
  def device_description(user_agent)
    device = DeviceDetector.new(user_agent)
    "#{device.name} / #{device.os_name}"
  end

  def device_type_icon(user_agent)
    device = DeviceDetector.new(user_agent)

    case device.device_type
    when "tablet"
      "fa fa-tablet"
    when "smartphone"
      "fa fa-phone"
    when "desktop"
      "fa fa-desktop"
    end
  end
end
```

That's it! 🤗

Inspired by:
- [vitobotta - Manage active sessions in Rails](https://vitobotta.com/2016/10/19/manage-active-sessions-)
- [adamcooke/authie](https://github.com/adamcooke/authie)
