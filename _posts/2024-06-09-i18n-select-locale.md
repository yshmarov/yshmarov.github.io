---
layout: post
title: "i18n basics. Change current app language."
author: Yaroslav Shmarov
tags: i18n translations locales
thumbnail: /assets/thumbnails/globe.png
---

Previously I wrote about [managing translations with gem i18n-tasks]({% post_url 2024-06-08-i18n-translation-tools %})

Here's how you can let users manually switch the current language.

First, be sure to have your application i18n defaults set:

```ruby
# config/application.rb
  config.i18n.default_locale = :en
  config.i18n.available_locales = %i[en fr nl es de it pl pt ro ua]
  config.i18n.raise_on_missing_translations = true
```

Now you need to override the `default_locale` by setting `I18n.locale = :de` in `application_controller`.

### Set locale from URL

Namespace ALL the translatable routes:

```ruby
# config/routes.rb
  # scope "(:locale)", locale: /en|es/ do
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    resources :tags, only: %i[index show]
    resources :playlists, only: %i[index show]
  end
```

This way, the below routes are equivalent, and both respond to `params[:locale]`:

```ruby
https://localhost:3000/en/posts
https://localhost:3000/posts?locale=en
```

`default_url_options` will append the current locale to all links in your app, so that the user is redirected properly:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_locale

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
```

Finally, add links to open page in a different locale:

```ruby
# switch locales & redirect to root 
<%= link_to 'English', root_path(locale: :en) %>
<%= link_to 'Spanish', root_path(locale: :es) %>
# switch locales & redirect to current path 
<%= link_to 'English', url_for(locale: :en) %>
<%= link_to 'Spanish', url_for(locale: :es) %>
# switch locales & redirect to current path with params
<%= link_to 'English', url_for(request.parameters.merge(locale: :en)) %>
<%= link_to 'Spanish', url_for(request.parameters.merge(locale: :es)) %>
```

### Set locale from session/cookies, or User preferences

The official Rails Guides [do not](https://guides.rubyonrails.org/i18n.html#storing-the-locale-from-the-session-or-cookies) store locale in session/cookie.

Add `language` attribute to `User` model:

```shell
# terminal
rails g migration add_language_to_users language:string
```

```ruby
# migration
  add_column :users, :language, :string, default: 'en'
```

Create a concern to set locale based on 

```ruby
# /app/controllers/application_controller.rb
  include SetLocale
```

```ruby
# /app/controllers/concerns/set_locale.rb
module SetLocale
  extend ActiveSupport::Concern

  included do
    before_action :set_locale

    private

    def set_locale
      if params["locale"].present?
        language = params["locale"].to_sym
        session["locale"] = language
        if user_signed_in?
          current_user.update(language: language)
        end
        redirect_to(request.referrer || root_path)
      elsif session["locale"].present?
        language = session["locale"]
      else
        language = I18n.default_locale
      end

      if user_signed_in? && current_user.language.present?
        language = current_user.language
      end

      I18n.locale = if I18n.available_locales.map(&:to_s).include?(language)
        language
      else
        I18n.default_locale
      end
    end
  end
end
```

Finally, show the User links to set current locale:

```ruby
<%#= @user.language %>
<%#= I18n.locale %>
<% I18n.available_locales.excluding(I18n.locale).each do |language| %>
  <%= link_to language, root_path(locale: language) %>
<% end %>
```
