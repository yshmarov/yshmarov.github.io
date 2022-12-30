---
layout: post
title: "Notes on using ActionMailer"
author: Yaroslav Shmarov
tags: ruby-on-rails action_mailer
thumbnail: /assets/thumbnails/gmail.png
---

### 1. Mailer setup for localhost/`development`

Use [`gem 'letter_opener'`](https://github.com/ryanb/letter_opener){:target="blank"}. This way you can see how emails look when they are delivered.

```ruby
# config/environments/development.rb
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
```

### 2. Mailer setup for `test`/`staging`

You might want to test real email delivery in PR apps / staging.
You should be sure that you do not deliver these test emails to real people!
The easiest solution would be to use an **AWS sandbox domain**.
This way the emails will be delivered only to users from your domain.
In the below example we **do not want** to get out of the sandbox:

![aws-sandbox.png](/assets/images/aws-sandbox.png)

### 3. Mailer setup for `production`

Check out my post: [Sending emails in production with Amazon SES]({% post_url 2021-02-08-send-emails-in-production-amazon-ses %}){:target="blank"}

### 4. Sending emails

Generate a mailer:

```shell
rails g mailer post post_created
```

Always use `deliver_later`, not `deliver_now`:

```ruby
# app/controllers/posts_controller.rb
PostMailer.with(user: current_user, post: @post).post_created.deliver_later
```

You can pass multiple params and attachments:

```ruby
# app/mailers/post_mailer.rb
class PostMailer < ApplicationMailer
  def post_created
    @user = params[:user]
    @post = params[:post]
    @greeting = "Hi"
    # attach from assets
    attachments['logo.png'] = File.read('app/assets/images/logo.png')
    # attach from /public folder
    attachments.inline['logo.png'] = File.read("#{Rails.root}/public/images/logo.png")
    # attach an ical event
    attachments['calendar-event.ics'] = { mime_type: 'application/ics', content: icalendar.to_ical }
    # attach an ActiveStorage file
    file = @user.avatar
    attachments['avatar.png'] = { mime_type: file.blob.content_type, content: file.blob.download }

    # mail options
    mail(
      from: "Yaroslav <hello@superails.com>",
      to: email_address_with_name(User.first.email, User.first.full_name), 
      cc: User.all.pluck(:email), 
      bcc: "secret@superails.com", 
      subject: "New post created"
    )
  end
end
```

Rendering attachments in the email html:

```ruby
# app/views/post_mailer/post_created.html.erb
<%= asset_url('/images/games/game-card-backgrounds/football.png', host: 'https://superails.com') %>
<%= image_tag attachments['logo.png'].url, style: 'max-width: 16em;' %>
<%= image_tag attachments['avatar.png'].url, alt: 'My Photo', width: 100 %>

<h1>Post#post_created</h1>
<%= @user.email %> create <%= @post.title %>
```

Styling emails with CSS is tricky: you can't be sure that different email clients (outlook/gmail) render the CSS in the same way.

I usually style emails with plain CSS, not a CSS framework.

### 5. Preview emails

Best way for previewing your email html without actually sending it to an inbox:

```ruby
# test/mailers/previews/post_mailer_preview.rb
class PostMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/post_mailer/post_created
  def post_created
    PostMailer.with(user: User.first, post: Post.first).post_created
  end
end
```

### 6. Writing tests

Minitest example:

```ruby
# test/mailers/post_mailer_test.rb
require "test_helper"

class PostMailerTest < ActionMailer::TestCase
  test "post_created" do
    mail = PostMailer.post_created
    assert_equal "Post created", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
```

Rspec example:

```ruby
# main/spec/mailers/game_spec.rb
require 'rails_helper'

RSpec.describe PostMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:post) { create(:post) }

  describe 'reminder' do
    let(:mail) { PostMailer.with(user:, game:).post_created }

    it 'renders the headers' do
      expect(mail.subject).to match('vs')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['hello@superails.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Post created')
      expect(mail.body.encoded).to match('logo')
      expect(mail.body.encoded).to match('avatar')
    end
  end
end
```

### 7. Updating default layout

```ruby
# app/mailers/application_mailer.rb
  default from: 'Yaro <hello@corsego.com>'
```

```diff
# app/views/layouts/mailer.html.erb
  <body>
    <%= yield %>
+    Regards, Yaroslav Shmarov
+    <br>
+    hello@superails.com
  </body>
</html>
```

That's it! 🎉🥳🍾
