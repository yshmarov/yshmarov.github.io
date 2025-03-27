---
layout: post
title: "AutoNumeric.js: The Best Currency Input Field for Rails"
author: Yaroslav Shmarov
tags: rails javascript stimulus autonumeric
thumbnail: /assets/thumbnails/rails-logo.png
---

[AutoNumeric.js](https://autonumeric.org) provides great formatting for currency/money input fields. I've used it in a few companies over the years.

![Autonumeric demo](/assets/images/autonumeric.mov)

Here's how to implement it in your Rails application with Stimulus:

```sh
bin/importmap pin autonumeric
rails g stimulus autonumeric
```

The Stimulus controller:

```js
import { Controller } from "@hotwired/stimulus";
import AutoNumeric from "autonumeric";

export default class extends Controller {
  static values = {
    min: { type: Number, default: 0 },
    max: { type: Number, default: 999999.99 },
  };

  connect() {
    const autoNumericOptions = {
      decimalCharacter: ".",
      decimalPlaces: 2,
      digitGroupSeparator: ",",
      maximumValue: this.maxValue,
      unformatOnSubmit: true,
      currencySymbol: "€",
      currencySymbolPlacement: "p", // 'p' for prefix
      modifyValueOnWheel: false,
      rawValueDivisor: 0.01,
    };

    new AutoNumeric(this.element, autoNumericOptions);
  }
}
```

Use in a rails text_field. Autonumeric requires you to use `text_field`, not `number_field`.

```ruby
<%= form.text_field :amount, data: { controller: "autonumeric" }, class: "" %>
```

This will:

- Automatically formats numbers as currency (e.g., "$1,234.56")
- Prevents invalid input
- Handles decimal places correctly
- Supports maximum value limits

P.S. Please always store money in `bigint`. Not `integer` or `float`. Stripe stores amounts in **cents** and so should you!
