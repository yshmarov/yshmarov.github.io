---
layout: post
title: "SaaS: How to code the subscriptions business model. Advanced level"
author: Yaroslav Shmarov
tags: 
- ruby on rails
- tutorial
- premium
- subscription
- saas
- mvp
- startup
thumbnail: https://cdn.shopify.com/s/files/1/1061/1924/products/Money_Bag_Emoji_grande.png?v=1571606064
---

In the previous post 

2020-11-19-how-to-code-the-subscription-business-model-saas-service-as-a-service-part-1

we added basic subscription functionality to our `User` model. 

Now we will build a complete subscription architecture that can be connected to any model.

Schema of how the architecture will look: 
![subscription-uml-2](/assets/2020-11-23-how-to-code-the-subscription-business-model-saas-service-as-a-service/subscription-uml-2.png)

A `Customer` can `Subscribe` to a `Product` at a certain `Price`. 

To prolongue the subscription, he is `Charged`.

Let's understand it:

* ### **In real life** you sell `Products`.

`Product` = a set of useful **features**. 

`Product` feature examples:
* `{max_users: 10, annoying_adds: false}`
* `{max_users: 1, annoying_adds: true}`
* `{sms_count: 100}`
* `{product_category: toothpaste, weight: 100g, brand: colgate, formula: wz-655}`

```
# product.rb

#  name      :string
#  features  :jsonb (hash)
```

* ### One `Product` can be sold at different `Prices`.

`Price` contains `amount`, `currency`, `inteval`. 

`Price` Examples: 
* `100 USD Yearly`
* `10 PLN Monthly`
* `3.99 EUR Onetime`

A price can be `active` (available to buy at), or inactive (no new subscriptions at this price)

```
# price.rb

#  product_id   :integer
#  amount       :integer # always keep money in integer. last 2 digits are cents
#  currency     :string # USD / UAH / PLN / EUR ...
#  inteval      :string # weekly / monthly / yearly / forever
#  active       :boolean # if you want to draft new prices or disable old prices for new subscriptions

belongs_to :product
```

* ### `Subscription` = time-limited access to a `Product`.

```
# subscription.rb

# price_id            :integer
# subscribable_id     :integer  # customer
# subscribable_type   :string   # customer
# ends_at             :datetime

belongs_to :price
belongs_to :subscribable, as: :polymorphic
has_many :charges
```

* ### `Customer` = The entity that is billed. 

`Customer` = Subscriber = User = Team = Organization = Account = Company

This can be an individual user, or an organization account with many users (Slack team)

```
# customer.rb

# email   :string # for sending transactional emails

include Subscribable # this will connect our customer model to the subscription engine
```

* ### The `Subscribable` module

```
# models/concerns/subscribable.rb

module Subscribable

  has_one :subscription
  has_many :charges
  
  def cancel_subscription
  end

  def charge_and_update_subscription
  end

  def active?
    ends_at > Time.now
  end

end
```

* ### Enforcing subscription in controllers

```
# controllers/concerns/require_subscription.rb
module RequireSubscription
  extend ActiveSupport::Concern
  included do
  end
end
```

```
# controllers/concerns/require_active_subscription.rb
module RequireActiveSubscription
  extend ActiveSupport::Concern
  included do
  end
end
```

* ### `Customer` is `Charged` to make a `Subscription` `active`

```
# charge.rb

# subscription_id     :integer
# subscribable_id     :integer  # customer
# subscribable_type   :string   # customer
# amount              :integer  # to track how much was paid at this moment of time

belongs_to :subscription
belongs_to :subscribable, as: :polymorphic
```

```
# charges_controller.rb

def create
  @charge.amount = current_user.premium_price

  # PAYMENT PROVIDER LOGIC GOES HERE

  if @charge.save
    current_user.update(ends_at: Time.now + current_user.premium_interval)
  end
end
```

This way whenever a user makes a payment and creates a `charge`, 
his subscription `ends_at` is set to a later date based on `premium_interval`.

In this simple example `charges` are not automatic and the user has to explicitly `create` a `charge`.

=subscriptions=
- Plans can be active and inactive (for new subscriptions)
- replace plan.max_members with hash field
- add description to plans
XX add_trial_days_to_plans trial_days:integer
XX free subscription - no charges required and not possible

#subscription.rb

def status
	incomplete
	incomplete_expired
	trialing
	active
	past_due
	cancelled
	unpaid
end


That's it! 🤠

This deserves being turned into a separate gem.
Oh, wait! There is a gem for this: [gem "pay"](https://github.com/pay-rails/pay/){:target="blank"}
The gem covers most of the material above.

Inspiration: 
[stripe subscription docs](https://stripe.com/docs/api/subscriptions/){:target="blank"}
