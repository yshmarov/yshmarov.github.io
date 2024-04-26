---
layout: post
title: Embedded Stripe Checkout
author: Yaroslav Shmarov
tags: stripe
thumbnail: /assets/thumbnails/stripe.png
---

😖 I really dislike [Stripe Elements](https://stripe.com/en-bg/payments/elements): you have to build and style the checkout form yourself.

![stripe-checkout-elements.png](/assets/images/stripe-checkout-elements.png)

🤩 Instead, [stripe-hosted full screen checkout](https://stripe.com/en-bg/payments/checkout) is a much better approach where you outsource all the payment logic to Stripe. It looks great:

![stripe-checkout-hosted.gif](/assets/images/stripe-checkout-hosted.gif)

Heres a [Github Repo](https://github.com/corsego/rails-7-stripe-subscriptions/commits/main/) where I have it implemented.

Stripe Hosted Checkout on SupeRails:

![stripe-checkout-hosted-superails.gif](/assets/images/stripe-checkout-hosted-superails.gif)

🥰🥰 But now you can use [Embedded Stripe Checkout](https://docs.stripe.com/payments/accept-a-payment?platform=web&ui=embedded-form) **inside** your app and keep your branding!

![stripe-checkout-embedded-superails.gif](/assets/images/stripe-checkout-embedded-superails.gif)

### Here's how you can implement Embedded Stripe Checkout:

Create a pricing page that redirects to the checkout page

```ruby
# config/routes.rb
  get "pricing", to: "stripe/checkout#pricing"
  get "checkout/new", to: "stripe/checkout#checkout", as: "new_checkout"
```

[Stripe Embedded Checkout API](https://docs.stripe.com/checkout/embedded/quickstart) has `ui_mode: :embedded` and `return_url` params that you should set:

```ruby
# app/controllers/stripe/checkout_controller.rb
  # GET
  def pricing
    lookup_key = %w[month year lifetime]
    @prices = Stripe::Price.list(lookup_keys: lookup_key, active: true,
                                 expand: ['data.product']).data.sort_by(&:unit_amount)
  end

  # GET
  def checkout
    price = Stripe::Price.retrieve(params[:price_id])
    @session = Stripe::Checkout::Session.create({
                                                  customer: current_user.stripe_customer_id,
                                                  # allow_promotion_codes: true,
                                                  # automatic_tax: {enabled: @plan.taxed?},
                                                  # consent_collection: {terms_of_service: :required},
                                                  # customer_update: {address: :auto},
                                                  # payment_method_collection: :if_required,
                                                  line_items: [{
                                                    price:,
                                                    quantity: 1
                                                  }],
                                                  mode: mode(price),
                                                  return_url: user_url(current_user),
                                                  ui_mode: :embedded
                                                })
  end

  private

  MODES = {
    'recurring' => 'subscription',
    'one_time' => 'payment',
    'setup' => 'setup'
  }.freeze

  def mode(price)
    MODES[price.type]
  end
```

Display links to checkout for each different price:

```ruby
# app/views/stripe/checkout/pricing.html.erb
<% @prices.each do |price| %>
  <%= link_to "Checkout" new_checkout_path(price_id: price.id) %>
<% end %>
```

This will redirect to the checkout page. You will need some JS to embed the Stripe Checkout.

```ruby
# app/views/stripe/checkout/checkout.html.erb
<%= javascript_include_tag "https://js.stripe.com/v3/" %>

<%= tag.div data: {
  controller: "stripe--embedded-checkout",
  stripe__embedded_checkout_public_key_value: Rails.application.credentials.dig(Rails.env, :stripe, :public),
  stripe__embedded_checkout_client_secret_value: @session.client_secret
} %>
```

```shell
rails g stimulus stripe/embedded_checkout
```

```js
// app/javascript/controllers/stripe/embedded_checkout_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    publicKey: String,
    clientSecret: String,
  }

  async connect() {
    this.stripe = Stripe(this.publicKeyValue)
    this.checkout = await this.stripe.initEmbeddedCheckout({clientSecret: this.clientSecretValue})
    this.checkout.mount(this.element)
  }

  disconnect() {
    this.checkout.destroy()
  }
}
```

That's it! Now you have the latest, coolest Stripe Checkout!

Don't forget to also add:
- Webhooks to create customers, handle successful and failed payments, subscription state changes
- Billing portal for user to manage plan, change payment methods, see invoice history

See examples here: [github.com/corsego/rails-7-stripe-subscriptions](https://github.com/corsego/rails-7-stripe-subscriptions/commits/main/)
