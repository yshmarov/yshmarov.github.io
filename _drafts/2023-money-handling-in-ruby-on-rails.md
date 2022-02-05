

My rule #1 - always handle money as `integer`.

Represents monetary values as integers, in cents. This avoids floating point rounding errors."

https://github.com/RubyMoney/money
https://github.com/RubyMoney/money-rails


Moreover, as Stripe docs suggests, 
expect amounts to be provided in a currency’s smallest unit. For example, to charge 10 USD, provide an amount value of 1000 (that is, 1000 cents).
For zero-decimal currencies, still provide amounts as an integer but without multiplying by 100. For example, to charge ¥500, provide an amount value of 500.

https://stripe.com/docs/currencies#zero-decimal
