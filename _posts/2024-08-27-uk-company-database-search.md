---
layout: post
title: Search and Autocomplete UK Company Information
author: Yaroslav Shmarov
tags: uk open-data company-search
thumbnail: /assets/thumbnails/uk.png
---

Previousl I wrote about [finding a company in the French national company database]({% post_url 2024-08-02-french-company-database-search %}).

Now let's **search 🇬🇧UK companies via API**.

The UK government nicely provides a free API.

[API Docs](https://developer-specs.company-information.service.gov.uk/companies-house-public-data-api/reference).

You can [create a free account](https://developer.company-information.service.gov.uk) to get an API token.

![UK company search - get API key](/assets/images/uk-company-search.png)

Here's a job that let's you search for company details. The result is most accurate if you input the national company identifier. 

To perform the search with your API key, you will need to encode it with Base64!

```shell
curl -H "Authorization: Basic MyApiKey" "https://api.company-information.service.gov.uk/search/companies?q=skibby"
# => {"error":"Invalid Authorization","type":"ch:service"}%
echo -n MyApiKey | base64
# => MyEncodedApiKey
curl -H "Authorization: Basic MyEncodedApiKey" "https://api.company-information.service.gov.uk/search/companies?q=skibby"
# => success
```

Example with a Rails job:

```ruby
# API DOCS: PAYLOAD EXAMPLE
# https://developer-specs.company-information.service.gov.uk/companies-house-public-data-api/resources/companysearch?v=latest

# rails g job UkCompanySearch
# bundle add faraday
# result = UkCompanySearchJob.perform_now('skibby')
class UkCompanySearchJob < ApplicationJob
  queue_as :default
  def perform(query)
    api_key = Rails.application.credentials.dig(:company_search, :gb)
    url = "https://api.company-information.service.gov.uk/search/companies?q=#{query}"

    connection = Faraday.new do |conn|
      conn.headers["Authorization"] = "Basic #{Base64.strict_encode64(api_key + ":")}"
      conn.adapter Faraday.default_adapter
    end

    response = connection.get(url)

    if response.success?
      JSON.parse(response.body)
    else
      {error: response.status, message: response.reason_phrase}
    end
  end
end
```

Well, that's it!
