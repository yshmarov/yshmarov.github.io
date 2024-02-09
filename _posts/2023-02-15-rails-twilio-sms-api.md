---
layout: post
title: "Send SMS with Twilio in Rails"
author: Yaroslav Shmarov
tags: ruby rails twilio
thumbnail: /assets/thumbnails/sms-twilio-logo.png
youtube_id: 1Hfaq2vH2EQ
---

Over the years SMS has become a much less important way of **communication**, but it can still be useful for receiving important **system notifications**.

Common reasons to be using SMS in 2023:
- Identity verification (confirm phone number via SMS)
- Important appointment reminders (doctors appointment)
- 2 Factor Authentication via SMS (my grandma does not use 2FA apps)

For example, when I was creating a chatgpt account, it required a confirmed phone number. Most likely to decrease the amount of bots:

![sms-verify-chatgpt.png](/assets/images/sms-verify-chatgpt.png)

[**Twilio**](https://www.twilio.com/docs/libraries/ruby){:target="blank"} offers a very easy way to send SMS using Rails.

### Access Twilio API keys

After creating an account, navigate to [https://console.twilio.com](https://console.twilio.com){:target="blank"}

![sms-twilio-api-keys.png](/assets/images/sms-twilio-api-keys.png)

Save twilio credentials in your apps `credentials.yml`:

```ruby
twilio:
  account_sid: AC714f90d7750d7cf2
  auth_token: c8671c5e8233b0
  from_phone_number: "+18305801212"
  dummy_to_phone_number: "+48537623523"
```

If you send messages while in trial mode, you must first verify your 'To' phone number (`dummy_to_phone_number`). Ensure that your phone number is [in a valid geo](https://console.twilio.com/?frameUrl=/console/sms/settings/geo-permissions){:target="blank"} & [is verified](https://console.twilio.com/us1/develop/phone-numbers/manage/verified){:target="blank"}.

### Send SMS with Twilio in a Rails app

Install [`gem 'twilio-ruby'`](https://github.com/twilio/twilio-ruby){:target="blank"}:

```shell
bundle add twilio-ruby
```

Create a Service that you can call in your app:

```ruby
# app/services/twilio/send_sms_service.rb
module Twilio
  class SendSmsService
    require 'twilio-ruby'

    def call(body, to_phone_number)
      account_sid = Rails.application.config_for(:settings).dig(:credentials, :twilio, :account_sid)
      auth_token = Rails.application.config_for(:settings).dig(:credentials, :twilio, :auth_token)
      from_phone_number = Rails.application.config_for(:settings).dig(:credentials, :twilio, :from_phone_number)
      dummy_to_phone_number = Rails.application.config_for(:settings).dig(:credentials, :twilio, :dummy_to_phone_number)

      begin
        @client = Twilio::REST::Client.new account_sid, auth_token
        message = @client.messages.create(
                           body:,
                           from: from_phone_number,
                           to: to(to_phone_number),
                           #  media_url: ['https://demo.twilio.com/owl.png'] # MMS example
                          )
        puts message.sid
      rescue Twilio::REST::TwilioError => exception
        puts exception.message
      end
    end

    private

    def to(to_phone_number)
      return dummy_to_phone_number if Rails.env.development?

      to_phone_number
    end
  end
end
```

Call the service and send an SMS:

```ruby
body = 'some text'
to_phone_number = '+38050554470367'
Twilio::SendSmsService.new.call(body, to_phone_number)
```

### Testing with Rspec

Assuming `from_phone_number = 18305803384`, the test and stubbed Webmock request could look like this:

```ruby
# spec/services/send_sms_service_spec.rb
require 'rails_helper'

RSpec.describe Twilio::SendSmsService do
  let(:body) { 'lorem ipsum' }
  let(:to_phone_number) { '+123456789' }
  let(:twilio_api_url) { "https://api.twilio.com/2010-04-01/Accounts/#{Rails.application.config_for(:settings).dig(:credentials, :twilio, :account_sid)}/Messages.json" }
  subject(:call) { described_class.new.call(body, to_phone_number) }

  before do
    stub_request(:post, twilio_api_url).to_return(status: 200)
  end

  context 'calls twilio api' do
    it 'sends request' do
      call
      expect(WebMock).to have_requested(:post, twilio_api_url).with(body: 'Body=lorem+ipsum&From=%2B18305803384&To=%2B123456789')
    end
  end
end
```

### Final thoughts, next steps

Ideally, before sending transactional SMS messages, I would build a mechanism for the user to verify his phone number.

Here's how it would work:
1. User inputs his phone number.
2. We generate random 6-digit token and send it to the user via SMS.
3. User receives SMS, submits token in a form.
4. If the token that the user submits is correct, we mark his phone number as verified.

Also, we might be able to track if an SMS has been delivered on Twilio's side. Than we would mark the phone number as invalid if the SMS is not deliverable.

We can also try to validate the to_phone_number via Twilio lookup API.

It all depends on your unique usecase and how far your are willing to go :)
