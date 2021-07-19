---
layout: post
title: "config_for settings.yml"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails settings config_for config yml
thumbnail: /assets/thumbnails/cog.png
---

**config/settings** - approach to set default values and collections in a Rails application. Good for storing business logic default values, collections, texts

[config_for docs](https://api.rubyonrails.org/classes/Rails/Application.html#method-i-config_for){:target="blank"}

alternatively you can use [gem config](https://github.com/rubyconfig/config){:target="blank"}

create `/config/settings.yml`:
```
production:
  url: http://127.0.0.1:8080
  namespace: my_app_production

development:
  url: http://localhost:3001
  namespace: my_app_development

shared:
  foo:
    bar:
      baz: 1
  languages:
    en: english
    de: german
    fr: french
```

create `/config/programming.yml`:
```
shared:
  languages:
    ruby: Ruby
    python: Python
  seniority_levels:
    junior: Junior
    middle: Middle
    senior: Senior
```

getting values in the rails console:
```
Rails.application.config_for(:settings).dig(:languages).to_h.invert.to_a
=> [["english", :en], ["german", :de], ["french", :fr]] 

Rails.application.config_for(:settings).dig(:languages)
=> {:en=>"english", :de=>"german", :fr=>"french"} 

Rails.application.config_for(:settings).dig(:namespace)
=> "my_app_development" 

Rails.application.config_for(:programming).dig(:languages)
=> {:ruby=>"Ruby", :python=>"Python"} 
```

use as select in a form:
```
<%= form.select :language, Rails.application.config_for(:settings).dig(:languages) %>
=> select from [en, de, fr], save to database [english, german, french]
<%= form.select :language, Rails.application.config_for(:settings).dig(:languages).to_h.invert.to_a %>
=> select from [english, german, french], save to database [en, de, fr]
```
