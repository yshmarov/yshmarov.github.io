---
layout: post
title: "Add Stripe Checkout to a Rails app"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stripe
thumbnail: /assets/thumbnails/stripe.png
---

1. Minimal (stripe products, prices, payments). No current user
2. Pay per product (local products with prices), pay to buy
3. Pay per cart (cart object, quantities)

https://web-crunch.com/posts/stripe-checkout-billing-portal-ruby-on-rails

* [example Stripe-Rails e-commerce app](https://github.com/corsego/shoplify)
* [example Stripe-Rails SaaS app](https://github.com/corsego/saasblog)


### 2. Add Stripe info to your Users (Customers)

```sh
rails g migration add_stripe_fields_to_user stripe_customer_id plan subscription_status current_period_end:datetime
```

```ruby
  t.string "stripe_customer_id"
  t.string "plan"
  t.string "subscription_status", default: "incomplete"
  t.datetime "current_period_end"
```

```ruby
<%= link_to 'Pricing', pricing_path %>
<%= link_to "Manage Billing", billing_portal_create_path, method: :post if current_user.plan? %>
<%= current_user&.stripe_customer_id %>
<%= current_user&.plan %>
<%= current_user&.subscription_status %>
<%= current_user&.current_period_end.strftime('%d/%m/%Y') %>
```

###

```ruby
# app/models/user.rb
  def active?
    subscription_status == 'active' && current_period_end > Time.zone.now
  end

  def incomplete?
    subscription_status == 'incomplete'
  end

  def cancelled?
    subscription_status == 'cancelled'
  end

  after_create do
    # first user is admin
    update(admin: true) if User.count == 1
    # stripe
    customer = Stripe::Customer.create(email: email)
    update(stripe_customer_id: customer.id)
  end
```


```shell
rails g controller static_pages landing_page --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework
rails g controller static_pages pricing
rails g controller checkout create --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --skip-template-engine
rails g controller webhooks stripe --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --skip-template-engine
rails g controller billing_portal create
```

config/routes.rb
```ruby
  get 'pricing', to: 'static_pages#pricing'
  post "checkout/create", to: "checkout#create", as: "checkout_create"
  post "billing_portal/create", to: "billing_portal#create", as: "billing_portal_create"
  resources :webhooks, only: [:create]
  post 'webhooks/stripe', to: 'webhooks#stripe'
```

```ruby
# app/views/static_pages/pricing.html.erb
<h1>Pricing</h1>
<% @pricing.each do |price| %>
  <%= price.product.name %>
  <%= price.unit_amount/100 %>
  <%= price.currency %>
  <%= price.recurring.interval if price&.recurring&.interval %>
  <% if user_signed_in? && current_user.stripe_customer_id.present? %>
    <%= link_to checkout_create_path(price: price.id), method: :post, remote: true, data: { disable_with: "validating..."} do %>
      Subscribe for <%= price.unit_amount/100 %> 
      <% if price&.recurring&.interval %>
        per <%= price.recurring.interval %>
      <% else %>
        once
      <% end %>
    <% end %>
  <% else %>
    <%= link_to "Create an account to subscribe", new_user_registration_path %>  
  <% end %>
<% end %>
```

```ruby
# app/controllers/static_pages_controller.rb
class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[pricing]

  def pricing
    product = if Rails.env.development?
                'prod_Jb4Bx2ZIW9hVao'
              elsif Rails.env.production?
                'prod_JldPahbrcsR4OW'
              end
    redirect_to root_path, alert: 'You are already subscribed' if user_signed_in? && current_user.plan.present?
    @pricing = Stripe::Price.list(product: product, active: true,
                                  expand: ['data.product']).data.sort_by(&:unit_amount)
  end
end
```

```ruby
# app/controllers/checkout_controller.rb
class CheckoutController < ApplicationController
  def create
    def mode
      price = Stripe::Price.retrieve(params[:price])
      case price.type
      when 'recurring'
        'subscription'
      when 'one_time'
        'payment'
      end
    end
    @session = Stripe::Checkout::Session.create({
      customer: current_user.stripe_customer_id,
      success_url: root_url,
      cancel_url: pricing_url,
      allow_promotion_codes: true,
      payment_method_types: ['card'],
      line_items: [
        { price: params[:price], quantity: 1 }
      ],
      mode: mode
    })
    redirect_to @session.url
  end
end
```

```ruby
# app/controllers/billing_portal_controller.rb
class BillingPortalController < ApplicationController
  def create
    portal_session = Stripe::BillingPortal::Session.create({
      customer: current_user.stripe_customer_id,
      return_url: root_url
    })
    redirect_to portal_session.url
  end
end
```

```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook)
      )
    rescue JSON::ParserError => e
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      puts 'Signature error'
      p e
      return
    end

    # Handle the event
    case event.type
    when 'customer.subscription.updated', 'customer.subscription.deleted', 'customer.subscription.created'
      subscription = event.data.object
      user = User.find_by(stripe_customer_id: subscription.customer)
      user.update(
        plan: subscription.items.data[0].price.recurring.interval,
        # plan: subscription.items.data[0].price.lookup_key,
        subscription_status: subscription.status,
        current_period_end: Time.zone.at(subscription.current_period_end).to_datetime
      )
    when 'checkout.session.completed'
      session = event.data.object
      if session.subscription.nil?
        session_with_expand = Stripe::Checkout::Session.retrieve({ id: session.id, expand: ['line_items'] })
        user = User.find_by(stripe_customer_id: session.customer)
        # session_with_expand.line_items.first.price.nickname
        session_with_expand.line_items.data.each do |line_item|
          user.update(
            # line_item.price.nickname = forever
            # plan: line_item.price&.nickname,
            # plan: line_item.price.nickname,
            plan: line_item.price.nickname.presence || 'eternal',
            subscription_status: 'active',
            current_period_end: Time.zone.now + 100.years
          )
        end
      end
    end

    render json: { message: 'success' }
  end
end
```

### Billing Portal


http://lvh.me:3000/webhooks
