---
layout: post
title: "Sending emails in production with Amazon SES"
author: Yaroslav Shmarov
tags: ruby-on-rails action_mailer amazon-ses aws sendgrid
thumbnail: /assets/thumbnails/aws.png
---

get the API keys here:

[https://eu-central-1.console.aws.amazon.com/ses/home?region=eu-central-1#smtp-settings:](https://eu-central-1.console.aws.amazon.com/ses/home?region=eu-central-1#smtp-settings:){:target="blank"}

Getting the API Keys:

![awsses0](/assets/send-emails-in-production-amazon-ses/awsses0.PNG)

![awsses1](/assets/send-emails-in-production-amazon-ses/awsses1.PNG)

![awsses2](/assets/send-emails-in-production-amazon-ses/awsses2.PNG)

![awsses3](/assets/send-emails-in-production-amazon-ses/awsses3.PNG)

HOWTO

production.rb:
```
config.action_mailer.default_url_options = {host: "corsego.herokuapp.com", protocol: "https"}
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true

config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  port: 587,
  address: 'email-smtp.eu-central-1.amazonaws.com',
  user_name: 'SMTP_CREDENTIALS_USER_NAME',
  password: 'SMTP_CREDENTIALS_PASSWORD',
  authentication: :plain,
  enable_starttls_auto: true
}
```
app/mailers/application_mailer.rb:
```
default from: "Corsego <hello@corsego.com>"
```

useful links:
*	[https://hixonrails.com/ruby-on-rails-tutorials/ruby-on-rails-action-mailer-configuration/](https://hixonrails.com/ruby-on-rails-tutorials/ruby-on-rails-action-mailer-configuration/){:target="blank"}
