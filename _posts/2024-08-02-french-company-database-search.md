---
layout: post
title: Search and Autocomplete French Company Information
author: Yaroslav Shmarov
tags: france open-data company-search
thumbnail: /assets/thumbnails/france.png
---

Let's build a tool to find 🇫🇷French companies and autocomplete their data into a form field. Here's how it will work: 

![french company data autocomplete](/assets/images/fr-company-search.gif)

French company web database:

- [https://annuaire-entreprises.data.gouv.fr/](https://annuaire-entreprises.data.gouv.fr/)
- [Example company 1](https://annuaire-entreprises.data.gouv.fr/entreprise/groupe-la-manufacture-833315252)
- [Exmaple company 2](https://annuaire-entreprises.data.gouv.fr/entreprise/trezy-887553303)

You don't have to pay for an API. You can use it **for free**! French company search API docs:

- [About API](https://annuaire-entreprises.data.gouv.fr/donnees/api-entreprises)
- [API docs](https://recherche-entreprises.api.gouv.fr/docs/#tag/Recherche-textuelle)

Search with CURL:

```shell
curl -X GET "https://recherche-entreprises.api.gouv.fr/search?q=la%20poste&page=1&per_page=1" -H  "accept: application/json"
curl -X GET "https://recherche-entreprises.api.gouv.fr/search?q=887553303&page=1&per_page=1" -H  "accept: application/json"
```

Search with Ruby:

```ruby
bundle add faraday
# rails c
require 'faraday'
name = "887553303"
base_url = 'https://recherche-entreprises.api.gouv.fr'
page = 1
per_page = 25
encoded_name = ERB::Util.url_encode(name)
url = "#{base_url}/search?q=#{encoded_name}&page=#{page}&per_page=#{per_page}"
response = Faraday.get(url)
results = JSON.parse(response.body)
names = results["results"].map { |h| h["nom_complet"] }
```

### Build the search-autocomplete

Run the generators:

```shell
rails g scaffold company info:text
rails db:migrate

# type in field and search
rails g stimulus company-search

# make HTTP requests from StimulusJS
bundle add requestjs-rails
./bin/rails requestjs:install

# make HTTP requests from Rails controller
bundle add faraday

# copypaste selected company info
rails g stimulus company-autocomplete
```

The form:

```ruby
# app/views/companies/_form.html.erb
<%= form_with(model: company, class: "space-y-4", data: { controller: "company-autofill" }) do |form| %>
  <div>
    <%= form.label :name %>
    <%= form.text_field :name, data: { company_autofill_target: "paste" }, readonly: true, class: "bg-gray-200 cursor-not-allowed w-full" %>
  </div>

  <div data-controller="company-search">
    <%= form.label :company %>
    <%= form.text_field :company, data: { action: "company-search#search" }, placeholder: "SIREN...", class: "w-full" %>
  </div>

  <div id="search_results" data-company-autofill-target="collection">
  </div>

  <div>
    <%= form.submit class: "rounded-lg py-3 px-5 bg-blue-500 text-white inline-block font-medium" %>
  </div>
<% end %>
```

When `:company` field is being filled in, make a turbo_stream request to the rails controller to perform search

```js
// app/javascript/controllers/company_search_controller.js
import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js";

// Connects to data-controller="company-search"
export default class extends Controller {
  search(event) {
    console.log(event.target.value)
    const query = event.target.value;

    // TOOD: add debounce
    if (query.length >= 3) {
      console.log('fetching')
      get(`/company_search/search?query=${event.target.value}`, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })
    }
  }
}
```

Add the routes for search:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :companies do
    collection do
      get :search
    end
  end
end
```

Perform search, display results in a `turbo_stream`:

```ruby
# app/models/company.rb
class Company < ApplicationRecord
  validates :info, presence: true

  def self.search_fr(name)
    base_url = 'https://recherche-entreprises.api.gouv.fr'
    page = 1
    per_page = 25
    encoded_name = ERB::Util.url_encode(name)
    url = "#{base_url}/search?q=#{encoded_name}&page=#{page}&per_page=#{per_page}"
    response = Faraday.get(url)

    if response.success?
      JSON.parse(response.body)
      # names = results["results"].map { |h| h["nom_complet"] }
    else
      { error: response.status, message: response.reason_phrase }
    end
  end
end
```

Perform search

```ruby
# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  def search
    query = params[:query]
    @results = Company.search_fr(query)
  end
end
```

And render results:

```ruby
# app/views/company_search/search.turbo_stream.erb
<%= turbo_stream.update 'search_results' do %>
  <% @results["results"].each do |result| %>
    <div style="border: 1px solid black; margin: 10px; padding: 10px;" class="hover:bg-blue-300 cursor-pointer" role="button" data-action="click->company-autofill#autofill">
      <%= result["nom_complet"] %>
      <%= result["siren"] %>
      <%= result["siege"]["adresse"] %>
      <%= result["siege"]["region"] %>
      <%= result["siege"]["code_postal"] %>
    </div>
  <% end %>
<% end %>
```

Finally, fill in the text field with the selected results' content:

```js
// app/javascript/controllers/company_autofill_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="company-autofill"
export default class extends Controller {
  static targets = [ "collection", "paste" ]

  autofill(e) {
    this.pasteTarget.value = e.target.textContent

    this.collectionTarget.innerHTML = ''
  }
}
```

That's it!
