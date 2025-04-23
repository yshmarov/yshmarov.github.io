---
layout: post
title: "Slack API. Send text, markdown and files to Slack"
author: Yaroslav Shmarov
tags: ruby-on-rails slack
thumbnail: /assets/thumbnails/slack-logo.png
youtube_id: RHn1UzwLqMw
---

Most companies that I've worked with use Slack for internal communication.

A very common feature request is to receive a Slack messagewhen something happens in the application.

This can be though of as receiving "webhooks" by your Slack app.

_Incoming webhooks are a simple way to post messages from external sources into Slack_.

Example notifications:

- "{email} signed up!"
- "{email} bought {product} for {price}"
- "daily stats" (cron job)
- "daily income CSV" (cron job)

To implement this kind of functionality, we can use Slack API.

First, create a Slack channel (obviously 🤷‍♂️).

Next, visit the [Slack API website](https://api.slack.com/apps) and create a bot:

![slack-1-create-app](assets/images/slack-1-create-app.png)

Easiest way - to **create an app via manifest**. Here's mine:

```yml
display_information:
  name: message bot
features:
  bot_user:
    display_name: message bot
    always_online: false
oauth_config:
  scopes:
    bot:
      - chat:write
      - chat:write.public
      - files:write
      - im:write
      - links:write
      - links.embed:write
settings:
  org_deploy_enabled: false
  socket_mode_enabled: false
  token_rotation_enabled: false
```

Alternatively - **create an app from scratch**.

After creation go to "OAuth & Permissions" tab:

![slack-2-oath-and-permissions](assets/images/slack-2-oath-and-permissions.png)

These are the permissions that I would usually select to send messages:

![slack-3-permission-scopes](assets/images/slack-3-permission-scopes.png)

Invite the bot to your slack workspace:

![slack-4-install-to-workspace](assets/images/slack-4-install-to-workspace.png)

Allow access:

![slack-4-allow-access](assets/images/slack-4-allow-access.png)

After that you will granted an API token. Copy it:

![slack-5-copy-token](assets/images/slack-5-copy-token.png)

Try to connect to the token via the console:

```shell
slack --slack-api-token=[token] auth test
# slack --slack-api-token=xoxb-123432423-rgwrgerge-657567 auth test
```

Works? Now let's make it work with Rails

### Slack API + Rails

Add the generated API key to your Rails app credentials:

```ruby
# credentials.yml
slack:
  slack_api_token: xoxb-123432423-rgwrgerge-657567
```

To comfortably interact with the bot using Ruby, install [gem slack-ruby-client](https://github.com/slack-ruby/slack-ruby-client):

```shell
bundle add slack-ruby-client
```

Initialize Slack token:

```ruby
# echo > config/initializers/slack.rb
# config/initializers/slack.rb
Slack.configure do |config|
  # config.token = xoxb-123432423-rgwrgerge-657567
  config.token = Rails.application.credentials.dig(:slack, :slack_api_token)
end
```

Connect to Slack API and send your first message on behalf of the "bot":

```ruby
client = Slack::Web::Client.new
client.auth_test
client.chat_postMessage(channel: '#general', text: 'Hello World', as_user: true)
```

Add a service that will allow you to connect to the Slack client in the future:

```ruby
# mkdir app/services
# echo > app/services/slack_client.rb
# app/services/slack_client.rb
module SlackClient
  def client
    Slack::Web::Client.new.tap(&:auth_test)
  rescue Slack::Web::Api::Errors::NotAuthed
    nil
  end

  module_function :client
end

# now you can use
SlackClient.client.chat_postMessage(channel: '#general', text: 'Hello World', as_user: true)
```

### Send markdown

The main difference between sending inline text and markdown is the inclusion of line breaks.

This can be accomplished with squiggly heredoc (`<<~`). This way you can have a string with `\n` line breaks:

````ruby
def text
  <<~TEXT
    :alert: *#something happened*
    `code inline`
    and
    ```
    code block
    ```
    that's it!
    a link: https://blog.superails.com
    a video: https://www.youtube.com/watch?v=dVbDkWbHX6M
  TEXT
end

# => ":alert: *#something happened*\n`code inline`\nand\n```\ncode block\n```\nthat's it!\na link: https://blog.superails.com\na video: https://www.youtube.com/watch?v=dVbDkWbHX6M\n"

SlackClient.client.chat_postMessage(channel: '#general', text:, as_user: true)
````

### Send a file

Sending an image from assets:

```ruby
filename = 'sample-image.png'
file_path = Rails.root.join('app', 'assets', 'images', filename).to_s
file = Faraday::UploadIO.new(file_path, 'image/png')
SlackClient.client.files_upload(
  channels: '#general',
  as_user: true,
  file:,
  title: 'file caption',
  filename:,
  initial_comment: 'normal text above file'
)
```

Example result:

![slack-image-upload-example](assets/images/slack-image-upload-example.png)

To send a text file, you would use `text/plain` [mime type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types):

```ruby
file_to_upload = 'test.txt'
Faraday::UploadIO.new(file_to_upload, 'text/plain')
```

If your app **generates a new file**, that you want to send, you can:

- save it to an external storage like S3 and attach form there (best option)
- save it directly into your app and attach it from there

In the below example I:

- use `gem caxlsx` to [export all users created today into an Excel file]({% post_url 2021-08-20-export-from-database-to-excel %}){:target="blank"}
- save the file to `app/assets/csv/filename.xlsx` using `IO.binwrite`
- send the `xls` file to Slack

```ruby
# requires gem caxlsx
def export_daily_users_to_slack
  users_for_period = User.where(created_at: Date.today.all_day)
    .order(created_at: :desc)
  xlsx = ActionController::Base.new.render_to_string(
    layout: false,
    handlers: [:axlsx],
    formats: [:xlsx],
    template: 'csv/users',
    locals: { users: users_for_period }
  )
  title = [Time.now.to_s(:dmy), 'Users'].join(' ')
  filename = title.concat('.xlsx')
  folder_path = Rails.root.join('app', 'assets', 'csv', filename).to_s
  FileUtils.mkdir_p 'app/assets/csv'
  IO.binwrite(folder_path, xlsx.to_s)

  file = Faraday::UploadIO.new(folder_path, 'xlsx')

  SlackClient.client.files_upload(
    channels: '#general',
    as_user: true,
    file:,
    title:,
    filename:,
    initial_comment: 'users created in the last 24 hours'
  )
end
```

Example result:

![slack-csv-import-example](assets/images/slack-csv-import-example.png)

### Testing with rspec

Test slack authentication, message delivery (considering you use `rspec`)

```ruby
# spec/operations/reports/users_csv_report_spec.rb
require 'rails_helper'

RSpec.describe Reports::UsersCsvReport do
  subject(:service) { described_class.call }

  before do
    stub_request(:post, 'https://slack.com/api/auth.test').to_return(status: 200)
    stub_request(:post, 'https://slack.com/api/files.upload').to_return(status: 200)
    stub_request(:post, "https://slack.com/api/chat.postMessage").to_return(status: 200)
  end

  it 'calls slack api and logs event' do
    service
    expect(WebMock).to have_requested(:post, 'https://slack.com/api/files.upload')
    expect(WebMock).to have_requested(:post, "https://slack.com/api/chat.postMessage").with(body: "abc")
  end
end
```

That's it!
