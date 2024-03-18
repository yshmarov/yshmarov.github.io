---
layout: post
title: "Guest User Record (guest mode)"
author: Yaroslav Shmarov
tags: authentication guest-mode
thumbnail: /assets/thumbnails/guest.png
---

Instead of presenting a sign up form to the user, consider creating a temporary guest record so the user can try out the application without filling in their information up front. They can then become a permanent member afterwards.

Usecases:
- Anonymous voting
- Restaurant self-checkout
- Ecommerce shopping cart without sign in

This was covered in [RailsCasts #393 Guest User Record](http://railscasts.com/episodes/393-guest-user-record), however I have a different approach.

Whenever the app is opened in a new browser, find or create a permanent cookie.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :current_guest_id
  helper_method :current_guest_id

  private

  def current_guest_id
    cookies.permanent.signed[:guest_id] ||= SecureRandom.uuid
  end
end
```

🚨🚨🚨

The problem with my approach - many conditions on whether there is a `current_guest_id` or `current_user` that are different entities. 

This approach is best for cases where you will not want a user to finally authenticate.

🚨🚨🚨

So, when a Guest creates a message, assign the `current_guest_id` to it;

Scope records to `current_guest_id` if there is no `current_user`;

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :set_message, only: %i[ show edit update destroy ]

  def index
    @messages = if current_user
                  current_user.messages
                else
                  Message.where(guest_id: current_guest_id)
                end
  end

  def create
    if current_user
      @message = Message.new(message_params)
      @message.guest_id = current_guest_id
    else
      @message = current_user.messages.new(message_params)
    end

    @message.save!
    redirect_to message_url(@message)
  end

  private

  def set_message
    @message = if current_user
                current_user.messages.find(params[:id])
               else
                Message.where(guest_id: current_guest_id).find(params[:id])
               end
  end
end
```

Show links only to the Guest that created them.

```ruby
link_to "Edit", edit_message_path(message) if message.guest_id == current_guest_id
```

Result:

![current_guest_views](/assets/images/current_guest_views.png)

Finally, assign guest records to a user when he signs in.

```ruby
# app/controllers/application_controller.rb
  # in Devise resource = User
  def after_sign_in_path(resource)
    assign_guest_records_to(resource)
  end

  def after_sign_up_path(resource)
    assign_guest_records_to(resource)
  end

  private

  def assign_guest_records_to(resource)
    Message.where(guest_id: current_guest_id).where(user_id: nil).update_all(user: resource, guest_id: nil)
    Post.where(guest_id: current_guest_id).where(user_id: nil).update_all(user: resource, guest_id: nil)
    Comment.where(guest_id: current_guest_id).where(user_id: nil).update_all(user: resource, guest_id: nil)
  end
```

Perfecto!
