---
layout: post
title: "Slack API. Send messages and files to Slack"
author: Yaroslav Shmarov
tags: ruby-on-rails slack
thumbnail: /assets/thumbnails/slack.png
---

Create slack bot, allow him to do X actions, invite him to selected channel(s)

[gem slack-ruby-client](https://github.com/slack-ruby/slack-ruby-client)

```shell
bundle add slack-ruby-client
```

```ruby
# credentials.yml
slack:
  slack_api_token: xoxb-123432423-rgwrgerge-657567
```

```ruby
client = Slack::Web::Client.new
client.auth_test
client.chat_postMessage(channel: '#general', text: 'Hello World', as_user: true)
```

send text
send markdown
send file

```ruby
# config/initializers/slack.rb
Slack.configure do |config|
  config.token = Rails.application.credentials.dig(:slack, :slack_api_token)
end
```

```ruby
# app/services/slack_client.rb
module SlackClient
  def client
    Slack::Web::Client.new.tap(&:auth_test)
  rescue Slack::Web::Api::Errors::NotAuthed
    nil
  end

  module_function :client
end
```

```ruby
# send markdown
class GameScheduleChangedReport
  attr_reader :game
  def initialize(game:)
    @game = game
    SlackClient.client.chat_postMessage(channel:, text:)
  end
  def text
    <<~TEXT
      :alert: *#{text_title}*
      Sport: #{game.name} #{Sport::EMOJI[game.slug.to_sym]}
      #{game.description}
      *Updated Game Details:*
      Home Team: *#{game.home_team.name}*
      Visiting Team: *#{game.visiting_team.name}*
      Venue: *#{game.venue.name}*
      Starts At: *#{game.starts_at}*
    TEXT
  end
  def channel
    return '#dev-notifications-testing' unless Rails.env.production?

    '#schedule-updates'
  end
end
```


https://github.com/slack-ruby/slack-ruby-client
https://github.com/caxlsx/caxlsx_rails
https://gist.github.com/deepzm/06fb2d34f480bd6b1e49

sending an image from assets file: Faraday::UploadIO.new('./app/assets/images/ben-infield.png', 'image/jpeg'),

```ruby
# frozen_string_literal: true

module Reports
  # :reek:InstanceVariableAssumption
  class UsersCsvReport
    extend Callable

    def call
      users_for_period = User.where(created_at: Date.today.all_day)
        .order(created_at: :desc)
      xlsx = ActionController::Base.new.render_to_string(layout: false,
        handlers: [:axlsx],
        formats: [:xlsx],
        template: "csv/users",
        locals: {users: users_for_period})

      filename = "user-list-export.xlsx"
      IO.binwrite("tmp/storage/#{filename}", xlsx.to_s)

      file = Faraday::UploadIO.new("./tmp/storage/#{filename}", "xlsx")

      # title = [Time.now.to_s(:dmy), 'Users'].join(' ')
      # filename = title.concat('.xlsx')
      # folder_path = Rails.root.join('app', 'assets', 'csv', filename).to_s
      # IO.binwrite(folder_path, xlsx.to_s)
      # file = Faraday::UploadIO.new(folder_path, 'xlsx')
      send_file(file, title, filename)
    end

    private

    def markdown_text
      <<~TEXT
        :alert: *#{vars[:title]}*
        Sport: #{game_sport.name} #{Sport::EMOJI[game_sport.slug.to_sym]}
        #{vars[:description]}
        *Updated Game Details:*
        Home Team: *#{game.home_team.name}*
        Visiting Team: *#{game.visiting_team.name}*
        Venue: *#{new_venue_name}*
        Starts At: *#{new_starts_at}*
      TEXT
    end

    def send_file(file, title, filename)
      slack_client.files_upload(
        channels: "#general",
        as_user: true,
        file:,
        title:,
        filename:,
        initial_comment: "Hello! Here is your users export."
      )
    end

    def send_markdown_post
      SlackClient.client.chat_postMessage(channel: "#general", text: markdown_text)
    end

    def send_test_post
      SlackClient.client.chat_postMessage(channel: "#general", text: "Congrats! It works for me")
    end

    def slack_client
      return @slack_client if defined? @slack_client

      @slack_client =
        begin
          Slack::Web::Client.new
            .tap(&:auth_test)
        rescue Slack::Web::Api::Errors::NotAuthed
          nil
        end
    end
  end
end
```


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
    expect(WebMock).to have_requested(:post, "https://slack.com/api/chat.postMessage").with(body: expected_body)
  end
end
```

