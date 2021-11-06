---
layout: post
title: "Meta Tags for better SEO. Add page title"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails SEO meta-tags
thumbnail: /assets/thumbnails/url.png
---

Meta tags help the browser and search engine to better interact with your website.
They are important for SEO.

Some most common meta tags:
* site title
* page title
* description
* tags
* author

Here's how they can look in the `<head>` of an HMTL document:
```html
<meta content="online education, course platform, video tutorials" name="keywords"/>
<meta content="Online Learning and Skill sharing platform" name="description"/>
<meta content="Yaroslav Shmarov" name="author"/>
<%= favicon_link_tag 'thumbnail.png' %>
<title>SupeRails</title>
```
### 1. Ruby on Rails: without a gem

app/views/application.html.erb
```ruby
<title>
  <%= content_for?(:title) ? yield(:title) : "SupeRails" %>
</title>
```

Now you can add a title tag on any page:

app/views/inboxes/index.html.erb
```ruby
<% content_for :title do %>
  <%= controller_name.humanize %>
  <%= action_name.humanize %>
  <%= Inbox.count %>
<% end %>
```

app/views/inboxes/show.html.erb
```ruby
<% content_for :title do %>
  <%= controller_name.humanize %>
  <%= @inbox.name %>
<% end %>
```

BONUS:

You might want to set up the app name dynamically based on `config/application.rb`.

Both below options work, but one is better

```diff
-- Rails.application.class.parent_name
++ Rails.application.class.module_parent_name
```

### 2. with [gem meta-tags](https://github.com/kpumuk/meta-tags){:target="blank"}

However, for more complex behaviour and more meta_tag types (like `description`, `tags`) - better use [gem meta-tags](https://github.com/kpumuk/meta-tags){:target="blank"}

console
```sh
bundle add meta-tags
rails generate meta_tags:install
```

* add `display_meta_tags` to the layout
* `reverse: true` - app name at the end like `Inboxes | New | SupeRails`

app/views/layouts/application.html.erb
```ruby
  <%= display_meta_tags site: Rails.application.class.module_parent.name,
                        description: 'Modern Ruby on Rails screencasts',
                        keywords: 'ruby, rails, ruby-on-rails', reverse: true %>
```

* if you do not override the tags - defaults from the layout will be displayed

app/controllers/posts_controller.rb
```ruby
  def index
     set_meta_tags title: %w[Inboxes All]
  end

  def show
    # set_meta_tags title: [@inbox.name, "Inboxes"]

    set_meta_tags title: @inbox.name,
                  description: @inbox.description,
                  keywords: 'seo, rails, ruby'
   end

   def new
     set_meta_tags title: "#{action_name.capitalize} #{controller_name.singularize.capitalize}"
   end
```

* don't forget that you can customize the settings in a config file

config/initializers/meta_tags.rb
```ruby
  config.title_limit = 200
  config.truncate_site_title_first = true
```

* [example of implemenation on SupeRails](https://github.com/yshmarov/superails/commit/d489756cc1f1b181e90f86c909d5ba9ce113ff1b){:target="blank"}
