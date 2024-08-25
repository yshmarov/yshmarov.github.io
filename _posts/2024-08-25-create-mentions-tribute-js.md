---
layout: post
title: "Add mentions to a text field with TributeJS"
author: Yaroslav Shmarov
tags: mentions tributejs stimulusjs
thumbnail: /assets/thumbnails/hashtag.png
---

Previously I wrote about [parsing #tags and @mentions]({% post_url 2022-10-25-search-by-hashtags-or-mentions %}).

Now, let's create mentions (find users and mention them).

Recently I added mentions to SupeRails. Now users can tag each other by Github username. A tagged user will see that he was mentioned.

[TributeJS](https://zurb.com/playground/tribute) is a good plugin for adding mentions.

We will use [requestjs-rails](https://github.com/rails/requestjs-rails) to make internal GET requests with JS (to get a list of usernames).

Initial setup:

```shell
rails new mentionsapp --main -d=postgresql -c=tailwind -a=propshaft
rails g scaffold User username
rails g scaffold message body:text
rails g scaffold mention user:references message:references
rails g stimulus mentions
bin/importmap pin tributejs
bundle add requestjs-rails
bin/rails requestjs:install
bundle add faker
```

Add some users to the database:

```ruby
# db/seeds.rb
# User.create username: Faker::Internet.username
usernames = %w[yshmarov marcoroth adrianthedev lucianghinda robzolkos dhh matz]
usernames.each do |username|
  User.create username: username
end
```

Form field with mentions enabled:

```ruby
# app/views/messages/form.html.erb
<%= form.text_area :body, required: true, style: 'width: 100%', rows: 3, data: { controller: 'mentions', mentions_target: 'input' } %>
```

Find user by username and return json:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    @users = if params[:query].present?
               User.where('username ILIKE ?', "%#{params[:query]}%")
             else
               User.none
             end

    respond_to do |format|
      format.json { render json: @users }
    end
  end
end
```

Stimulus controller to enable TributeJS and search for users:

```js
// app/javascript/controllers/mentions_controller.js
import { Controller } from "@hotwired/stimulus";
import Tribute from "tributejs";
import { get } from "@rails/request.js";

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.tribute = new Tribute({
      values: async (text, cb) => {
          const response = await get(`/users.json?query=${text}`);
          if (response.ok) {
            const users = await response.json;
            cb(users.map(user => ({ key: user.username, value: user.username })));
          }
      },
      selectTemplate: function (item) {
        return `@${item.original.value}`;
      },
    });
    this.tribute.attach(this.inputTarget);
  }

  disconnect() {
    this.tribute.detach(this.inputTarget);
  }
}
```

[Import TributeJS CSS](https://github.com/zurb/tribute/blob/master/dist/tribute.css)

After a message is created, parse mentioned usernames and create mentions

```ruby
# app/models/message.rb
  has_many :mentions

  after_create_commit do
    extract_mentions
  end

  private

  def extract_mentions
    mentioned_usernames = content.scan(/@(\w+)/).flatten
    mentioned_users = User.where(username: mentioned_usernames)
    mentioned_users.each do |mentioned_user|
      mentions.create(user: mentioned_user)
    end
  end
end
```

The second regex is actually better:

`(/@(\w+)/)` => `@foobar`.com

`(/@([\w._]+)/)` => `@foobar.com`

Display mentions in a text:

```ruby
module MessagesHelper
  def postprocess(text)
    text.gsub(/@([\w._]+)/) do |mention|
      username = mention[1..-1]
      link_to mention, "/users/#{username}", class: "text-blue-500"
    end
  end
end
```

```ruby
<%= simple_format postprocess(message.body) %>
```

Finally, test mention creation:

```ruby
# test/models/mention_test.rb
require 'test_helper'

class MentionTest < ActiveSupport::TestCase
  test 'create mention' do
    user = User.create username: "foo"
    message = Message.create!(content: "Hello @#{user.username}! How are you?")
    assert_equal 1, comment.mentions.count
    assert_equal 1, user.notifications.count
  end
end
```

That's it!
