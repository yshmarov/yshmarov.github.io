https://github.com/colinloretz/railsconf-webhooks

wtf webhooks?

when event happens in my app, send POST request to your app.

You give me the URL to which to send requests.

`WebhookEndpoint url:text secret_key:text` activities:text (array [])

Validation: `url` has to start with `https://`

I send requests with Faraday, with secret_key in the header and payload body json

Security? Authentication? API keys?

Track deliveries? Try to resend unsuccessful requests?

https://github.com/corsego/saasblog/blob/main/app/controllers/webhooks_controller.rb


```json
event:
  name: "customer.created", "customer.updated", "customer.deleted"
  payload:
    object: { id:, }
```

### PROVIDER SETUP (Send webhooks)

```ruby
def create
  if certificate.save
    event_name = "certificate.created"
    if webhook = user.webhooks.find_by(activities: event_name).any?
      Faraday.post(url: webhook.url) do |req|
        req.header["CERTIFICATEOWL_WHSEC"] = webhook.secret_key
        req.body = [event_name, certificate.to_json]
      end
    end
  end
end
```

```ruby
# app/models/certificate.rb
  belongs_to :team

  after_create do
    send_webhook if team.webhooks.any?
  end

  def send_webhook(event_name, payload)
  end
```

### CLIENT SETUP (Receive webhooks)

```ruby
# config/routes.rb
  resources :webhooks, only: :create
```

```ruby
# app/controllers/webhooks_controller.rb
skip_before_action :csfr

certificateowl_secret_key = Rails.credentials.dig(:certificate_owl, :webhook_key)

auth_token = request.headers['CERTIFICATEOWL_WHSEC']
return Unautharized unless auth_token == certificateowl_secret_key

payload = JSON.parse(request.body)
case payload.event
when "certificate.created"
end
```
