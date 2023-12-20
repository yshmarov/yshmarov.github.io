---
layout: post
title: Country select dropdown. Why does country_select gem even exist?
author: Yaroslav Shmarov
tags: rails country select
thumbnail: /assets/thumbnails/globe.png
---

[Gem "Countries"](https://github.com/countries/countries) offers a great dataset about each country:

![gem countries dataset](/assets/images/gem-countries-dataset.png)

Using the gem you can easily produce a collection of countries for **select**:

```ruby
# bundle add countries

def countries_for_select
  countries = ISO3166::Country.all.map! { |country| [country.translations[I18n.locale.to_s], country.alpha2] }
  countries.sort_by! { |country| country[0] }
end

# countries_for_select
# =>
# [["Afghanistan", "AF"],
#  ["Albania", "AL"],
#  ["Algeria", "DZ"],
#  ["American Samoa", "AS"],
#  ["Andorra", "AD"],
#  ["Angola", "AO"],
#  ["Anguilla", "AI"],
#  ["Antarctica", "AQ"],
#  ["Antigua and Barbuda", "AG"],
#  ["Argentina", "AR"]
#  ...
# ]
```

You can use this collection of key-values in a select dropdown:

```ruby
<%= form.select(:country, countries_for_select) %>
```

### 1. Form **with** Country Select gem

[Gem "Country Select"](https://github.com/countries/country_select) provides **select field helpers** based on the "Countries" gem, and some **simple_form styling**.

The country_select gem gives us a `form.country_select` helper:

```ruby
# bundle add countries

<%= form.country_select :address_format,
                        priority_countries: ["US","GB","AU","CA","DE","DK"],
                        selected: @setting.address_format&.upcase,
                        iso_codes: true
                        %>
```

It produces a list:

![dropdown with gem country select](/assets/images/gem-country-select-form-selector.png)

Notice the divider between the **priority countries** and **other countries**.

### 2. Form **without** Country Select gem

To mimic this exact behaviour of country_select gem, we would have to write all the following code:

```ruby
# app/helpers/country_select_helper.rb
module CountrySelectHelper
  PRIORITY_COUNTRIES = ["US", "GB", "AU", "CA", "DE", "DK"]

  def priority_countries
    countries = PRIORITY_COUNTRIES.map { |country| ISO3166::Country[country] }
    countries.map! { |country| [country.translations[I18n.locale.to_s], country.alpha2] }
    countries.sort_by! { |country| country[0] }
  end

  def other_countries
    all_countries = ISO3166::Country.all.map! { |country| [country.translations[I18n.locale.to_s], country.alpha2] }
    other_countries = all_countries - priority_countries
    # sort Åland Islands correctly
    other_countries.sort_by! { |country| country[0].tr("Å", "A") }
  end

  # add a divider
  def countries_for_select
    priority_countries + [["----------------", "----------------"]] + other_countries
  end
end
```

Now you can use `countries_for_select` with a regular form. To disable the divider, use the form `disabled` option:

```ruby
<%= form.select(:country,
                countries_for_select,
                disabled: ["----------------"]) %>
```

Result will be the same as above, but without this extra gem dependency.

Going further, using **option groups** is better than using a divider:

```ruby
<%= form.select(:country,
                {
                  "Popular": priority_countries,
                  other: other_countries
                }) %>
```

Result:

![form select with a divider](/assets/images/form-select-with-divider.png)

Looks good!

### 3. With [PolarisViewComponents](https://polarisviewcomponents.org/lookbook/) UI library

In my case I need a countries selector with a UI library that provides it's own [`form.polaris_select`](https://polarisviewcomponents.org/lookbook/inspect/select/disabled) instead of `form.select` or `form.country_select`.

![polaris view component polaris select example](/assets/images/polaris-country-select-lookbook.png)

Here's how I use the `CountrySelectHelper` with `polaris_select`:

```ruby
<%= form.polaris_select(:address_format,
                              disabled_options: ["----------------"],
                              options: countries_for_select,
                              selected: @setting.address_format&.upcase) %>
```

Final result:

![Polaris country select final result](/assets/images/polaris-country-select.gif)

That's it 🤠
