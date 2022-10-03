---
layout: post
title: "Minimal Stripe Checkout setup for Ruby on Rails"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stripe
thumbnail: /assets/thumbnails/stripe.png
---

The leanest working approach to receiving Stripe payments in a Rails app.

In this case we will create `Stripe::Product` and it's `Stripe::Price` in the console or in the [Stripe dashboard](https://dashboard.stripe.com/), and render these products in a rails view.

When clicking the "Buy" button next to a product, you will create a `Stripe::Checkout::Session` and redirect to a payment page.

After inputting your card details you will be redirected to either a `payment#success` or `payment#failure` page.

In this basic scenario **we will not store anything in our application database**.

### 1. Install Stripe

Install Stripe gem:

```shell
# terminal
bundle add stripe
```

Get your Stripe API keys from [dashboard.stripe.com](https://dashboard.stripe.com/).

Webhook path should be something like `localhost:3000/webhooks/create`.

Add your stripe API keys to credentials:

```ruby
# credentials.yml
development:
  stripe:
    id: "pk_test_51ISPa3AkDVZd6qQwf4fjX58Ou3AeOy22drkDmC1IrjItdPe7vAPoBEs5JOpo4MAkWEXU1yGpuvJhgkPkTLiqhdDQ00urtlbmMC"
    secret: "sk_test_51ISPa3AkDVZc6qQw5EH6HhZsokernfMA30s6HMKcZ93VAbv7dJBOmBfyTXTpUEDpKcAb99alKOR8VME94npm14Es00gHJ6yb4O"
    webhook: "whsec_f77d1b744dc8fccebaa2c44315ab7fbb15dfa7be4f97276ef1cf0edc1b25b04e"
production:
  stripe:
    id: "123"
    secret: "123"
    webhook: "123"
```

Add `stripe` initializer:

```ruby
# config/initializers/stripe.rb
Stripe.api_key = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret)
```

Now you can play with Stripe API in the console. Create some stripe products in `rails c`:

```ruby
stripe_product = Stripe::Product.create(name: "samsung galaxy s22")
stripe_price = Stripe::Price.create(currency: "usd", product: stripe_product, unit_amount: 119900, lookup_key: "galaxy 22")
stripe_price2 = Stripe::Price.create(currency: "eur", product: stripe_product, unit_amount: 99900, lookup_key: "galaxy 22 eur")
Stripe::Price.retrieve(stripe_price.id)
Stripe::Price.list(lookup_keys: ["galaxy 22", "galaxy 22 eur"])
Stripe::Price.retrieve("price_1LHowqAkDVZc6qQwIBkt24J1")
```

### 2. Display products and their prices. Buy Now button. Checkout Session

Generate
* a page to display the products/prices
* a checkout controller redirect to the stripe checkout
* a webhooks action to receive incoming requests from stripe

```shell
# terminal
rails g controller static_pages landing_page --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework
rails g controller checkout create success cancel --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework
rails g controller webhooks create --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --skip-template-engine
```

```ruby
# config/routes.rb
  root 'static_pages#landing_page'
  get 'checkout/success'
  get 'checkout/cancel'
  post 'checkout/create', to: 'checkout#create'
  post 'webhooks/create', to: 'webhooks#create'
```

Display prices, their products and payment buttons:

```ruby
# app/controllers/static_pages_controller.rb
def landing_page
  @prices = Stripe::Price.list(lookup_keys: ["galaxy 22", "galaxy 22 eur"], expand: ['data.product']).data.sort_by {|p| p.unit_amount}
end

# app/views/static_pages/landing_page.html.erb
<% @prices.each do |price| %>
  <br>
  <%= price.product.name %>
  <%= button_to checkout_create_path(price: price.id) do %>
    Buy now
    <%= price.unit_amount/100 %>
    <%= price.currency %>
  <% end %>
<% end %>
```

When clicking payment button, you will construct a dedicated stripe checkout page and redirect there:

* `success` - page to redirect to after successful payment
* `cancel` - when the user left the stripe checkout page without payment

```ruby
# app/controllers/checkout_controller.rb
class CheckoutController < ApplicationController
  def create
    @session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        price: params[:price],
        quantity: 1
      }],
      mode: 'payment',
      success_url: checkout_success_url,
      cancel_url: checkout_cancel_url
    })
    redirect_to @session.url
  end

  def success; end

  def cancel; end
end
```

Test different [Payment cards](https://stripe.com/docs/testing)

* `4242424242424242` - success
* `4000000000000002` - decline

### Webhook configuration

You can **send** data **TO** Stripe via the API,
and **receive** data **FROM** Stripe via webhooks.

Webhooks associated with the checkout flow:

```ruby
payment_intent.created
customer.created
payment_intent.succeeded
charge.succeeded
checkout.session.completed
```

Install [Stripe CLI](https://stripe.com/docs/stripe-cli) to accept webhooks locally:

```shell
# terminal
brew install stripe/stripe-cli/stripe
stripe login
stripe listen --forward-to localhost:3000/webhooks/create
# separate terminal window
stripe trigger payment_intent.succeeded
```

For the webhooks controller action, the code is mostly provided by Stripe.

However, for it to work in Rails, you need to add:

* `skip_before_action :verify_authenticity_token`
* `endpoint_secret = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook)`
* `status 200` = `render json: { message: 'success' }`
* `status 400` = `render json: { error: { message: e.message }}, status: :bad_request`

```ruby
  skip_before_action :verify_authenticity_token
```

```ruby
  private

  def endpoint_secret
    Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook)
  end
```

```diff
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
+  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
-      status 400
+       render json: { error: { message: e.message }}, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
-      status 400
+      render json: { error: { message: e.message, extra: "Sig verification failed" }}, status: :bad_request
      return
    end

    case event.type
    when 'charge.succeeded'
      charge = event.data.object
    when 'checkout.session.completed'
      session = event.data.object
    when 'customer.created'
      customer = event.data.object
    when 'payment_intent.created', 'payment_intent.succeeded'
      payment_intent = event.data.object
    when 'product.created'
      product = event.data.object
      puts "a product has been created"
    else
      puts "Unhandled event type: #{event.type}"
    end

-    status 200
+    render json: { message: 'success' }
  end

+  private

+  def endpoint_secret
+    Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook)
+  end
end
```

### 3. Next step

```ruby
product = Product.create(name: stripe_product.name, price: stripe_price.unit_amount, stripe_product_id: stripe_product.id)

product = Stripe::Product.create(name: 'pro')

stripe_product = Stripe::Product.create(name: "iphone 15")
stripe_price = Stripe::Price.create(currency: "usd", product: stripe_product, unit_amount: 77700, lookup_key: "iphone 15")
product = Product.create(name: stripe_product.name, price: stripe_price.unit_amount, stripe_product_id: stripe_product.id)
Stripe::Price.retrieve(stripe_price.id)
Stripe::Price.retrieve("price_1LHowqAkDVZc6qQwIBkt24J1")
Stripe::Price.create(
  product: product,
  unit_amount: 3900,
  currency: 'usd',
  recurring: {
    interval: 'month'
  },
  lookup_key: 'pro_monthly',
)

Stripe::Price.create(
  product: product,
  unit_amount: 39000,
  currency: 'usd',
  recurring: {
    interval: 'year'
  },
  lookup_key: 'pro_yearly',
)

Stripe::Price.create(
  product: product,
  unit_amount: 24900,
  currency: 'usd',
  lookup_key: 'pro_forever',
)
```

rails g scaffold product name price:integer

<%= button_to "Buy now!", checkout_create_path, params: {id: "price_1LHowqAkDVZc6qQwIBkt24J1"} %>

https://cjav.dev/posts/webhook-handler-rails/
