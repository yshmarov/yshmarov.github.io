---
layout: post
title: "SaaS: How to code the subscriptions business model. Elementary level (Spotify)"
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

Software as a Service (SaaS) = leasing = access to software with an end date.

You need to pay to postpone the end date.

From this perspective, a "One-time payment" = subscription with lifetime access.

### Example 1: Spotify subscription

In this case a user can buy a  `premium` subscription for `$12,11` for a limited time `1 month` to `remove adds`:

```
# user.rb

#  email      :string
#  password   :string
#  ends_at    :datetime

def premium_price
  1299.to_i # always keep money in integer. last 2 digits are cents
end

def premium_interval
  1.month
end

def premium?
  ends_at > Time.now
end

def show_annoying_adds?
  unless premium?
end
```

```
# charge.rb

# user_id     :integer
# amount      :integer # to track how much was paid at this moment of time

belongs_to :user
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

That's it! 🤠

****

The SaaS business model can usually have 2 `collection_methods`:
* `charge_automatically` 
* `send_invoice` 

Worth reading: [stripe subscription docs](https://stripe.com/docs/api/subscriptions/){:target="blank"}
