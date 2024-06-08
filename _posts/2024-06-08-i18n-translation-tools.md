---
layout: post
title: "Automatic i18n. Gem i18n-tasks. Phrase. Weglot."
author: Yaroslav Shmarov
tags: i18n translations locales phrase weglot
thumbnail: /assets/thumbnails/globe.png
---

Here's my experience with some premium translation tools, or why gem i18n-tasks is the best.

### [Weglot](https://www.weglot.com/)

At 🇦🇹 one previous company we used Weglot to translate the app directly in the browser.

**Weglot does not really support Turbo Drive**. We had big troubles making it work.

A basic installation looks more-less like this:

```ruby
# app/views/layouts/application.html.erb
<script type="text/javascript" src="https://cdn.weglot.com/weglot.min.js" data-turbo-track="reload"></script>
<%= javascript_tag nonce: true, "data-turbo-track": "reload" do -%>
  Weglot.initialize({api_key: "mySecretKey", wait_transition: true});
<% end -%>
```

Using Weglot was an expensive mistake.

### [Phrase](https://phrase.com/)

At 🇫🇷 another company we used Phrase.

To manage translations in our app, we used a Phrase CLI tool.

The phrase config file looked more-less like this:

```yml
# /.phrase.yml
phrase:
  access_token: foo
  project_id: bar
  pull:
    targets:
    - file: ./config/locales/<locale_name>.yml
      params:
        file_format: yml
    - file: ./public/locales/<locale_name>.json
      params:
        file_format: i18next
        fallback_locale_id: bazz
        include_empty_translations: true
        tags: frontend
```

The workflow looked like this:
1. Developer adds translation in app like `<%= I18n.t('posts.index.title) %>`
2. Developer goes to Phrase Strings app, adds to `en` locale `key=posts.index.title`, value `All posts`
3. Translate (automatically $) or manually with ChatGPT to other locales inside the Phrase tool.
4. run `phrase pull` to replace locales in the app with the updated locales from Phrase.

This process had a lot of friction, but the last drop was when they spiked up the price to EUR 750/month!

![Phrase price spike](/assets/images/phrase-price-spike.png)

In complete desparation, I [asked](https://twitter.com/yarotheslav/status/1798289447584518331) on Twitter, and I was recommended the [gem i18n-tasks](https://github.com/glebm/i18n-tasks).

### [gem i18n-tasks](https://github.com/glebm/i18n-tasks)

The new workflow looks like this:
1. Developer adds translation in app like `<%= I18n.t('posts.index.title) %>`
2. Developer goes to Phrase Strings app, adds to `en.yml` locale `posts.index.title`, value `All posts`
3. To translate to all available locales, run `i18n-tasks translate-missing --backend=openai`.

Here I just added a translation key and run the command. It was auto-translated in all the other YML files:

![gem-18n-tasks-run-translation](/assets/images/gem-18n-tasks-run-translation.png)

The task does not override existing translations, so you can override a translation manually if required 🤠.

To make the API work, keys should be kept in `/.env`. To ensure they work in your environment, run:

```shell
# .env
export OPENAI_API_KEY=sk-XXXX
export OPENAI_MODEL=gpt-4o
```

To check translation yml files for errors, run all commands from: `/test/i18n_test.rb`.

Be sure to have your application i18n defaults set:

```ruby
# config/application.rb
  config.i18n.default_locale = :en
  config.i18n.available_locales = %i[en fr nl es de it pl pt ro ua]
```

Gem i18n-tasks is great and I award it my personal gem of the month award! 🥇
