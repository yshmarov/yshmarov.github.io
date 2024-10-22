---
layout: post
title: "Gem Meta Tags for better SEO"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails SEO meta-tags
thumbnail: /assets/thumbnails/url.png
---

Meta tags are important for your website/webapp.

For example `title`, `description`, `favicon` help with for SEO and visibility:

![meta-tags-seo](assets/images/meta-tags-seo.png)

`og:image`, `og:title`, `og:description`, `og:url`, make link previews look nice when sharing on social:

![meta-tags-opengraph](assets/images/meta-tags-opengraph.png)

`title` tag makes browser tab readable:

![meta-tags-title](assets/images/meta-tags-title.png)

Here's how basic meta tags can look in the `<head>` of an HMTL document:

```html
<head>
  <title>Playlists | SupeRails</title>

  <link rel="icon" type="image/x-icon" href="/images/favicon.ico">

  <meta name="description" content="Gem Meta Tags for better SEO">
  <meta name="author" content="Yaroslav Shmarov">
  <meta name='copyright' content='SupeRails'>
  <meta name='language' content='EN'>
  <meta name='robots' content='index,follow'>
  <meta name='revised' content='Sunday, July 18th, 2010, 5:15 pm'>
  <!-- <meta name='revised' content="<%= @post.updated_at.strftime('%A, %B %eth, %Y, %l:%M %P')"> -->

  <meta property="og:title" content="Title of the shared link">
  <meta property="og:description" content="Description of the content">
  <meta property="og:image" content="URL of the image">
  <meta property="og:url" content="URL of the shared link">
  <meta property="og:type" content="Type of content">
  <meta property="og:site_name" content="Name of the website">
  <meta property="og:locale" content="Language and country of the content">
  <meta name="twitter:card" content="Type of Twitter card">
  <meta name="twitter:title" content="Title of the shared link">
  <meta name="twitter:description" content="Description of the content">
  <meta name="twitter:image" content="http://blog.corsego.com/assets/images/og/posts/meta-tags-without-a-gem.png">
  <meta name="twitter:url" content="https://blog.corsego.com/meta-tags-without-a-gem">
  <meta name="twitter:site" content="@rails">
  <meta name="twitter:creator" content="@yarotheslav"></head> 
```

ℹ️ the `keywords` meta tags is [no longer relevant](https://ahrefs.com/blog/meta-keywords/#:~:text=Meta%20keywords%20are%20meta%20tags,are%20not%20visible%20to%20visitors.&text=It%27s%20easy%20to%20add%20meta,%27%2C%20but%20should%20you%20bother%3F) ☠️

```diff
- <meta content="seo, meta-tags, ruby, rails" name="keywords"/>
```

### Add a favicon in a Rails app

First, add the favicon image into the `app/assets/images/thumbnail.png` folder.

```ruby
# app/views/layouts/application.html.erb
<head>
  <%= favicon_link_tag 'thumbnail.png' %>
  # produces
  <link rel="icon" type="image/x-icon" href="/assets/thumbnail.png">
```

Great in-depth article: [How to Favicon in 2024: Six files that fit most needs](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs)

### Dynamic `<title>` and other meta tags

If a page has a custom title, display it. Otherwise display just *"SupeRails"*:

```ruby
# app/views/layouts/application.html.erb
<title><%= content_for?(:title) ? yield(:title) : "SupeRails" %></title>
<%= yield :meta_tags %>
```

Now you can add a title tag to any page:

```ruby
# app/views/posts/index.html.erb
<% content_for :title do %>
  <%= pluralize Post.count, 'post' %>
  |
  <%#= Rails.application.class.parent_name %>
<% end %>
```

The above generates a title `5 posts | SupeRails`.

Set other meta tags; assuming you stored an image in `app/assets/images/banner.png`:

```ruby
# app/views/posts/index.html.erb
<% content_for :meta_tags do %>
  <meta name="og:description" content="<%= @event.location %>">
  <meta name="og:image" content="<%= asset_url('banner.png') %>">
<% end %>
```

```ruby
# app/views/posts/show.html.erb
<% content_for :title do %>
  <%= @post.title %>
  |
  <%= Rails.application.class.module_parent_name %>
<% end %>
# => "How to create meta tags | SupeRails"
```

### Image meta tag

Assuming you have a `Post` model that `has_one_attached :cover_image`, you can use it OR fallback to a default image if nothing is attached:

```ruby
def og_image(post)
  post.cover_image.attached? ? url_for(post.cover_image) : asset_url('banner.png')
end
```

```ruby
  <meta name="og:image" content="<%= og_image(post) %>">
```

### Use [gem meta-tags](https://github.com/kpumuk/meta-tags)

For more complex behaviour and more meta_tag types (like `description`, `tags/keywords`, `image`, [OpenGraph](https://ogp.me/)), better use [gem meta-tags](https://github.com/kpumuk/meta-tags).

```sh
# console
bundle add meta-tags
rails generate meta_tags:install
```

Add `display_meta_tags` to the layout, where you can set the default meta tags for all pages:

```ruby
# app/views/layouts/application.html.erb
<head>
  <%= display_meta_tags site: Rails.application.class.module_parent.name,
                        description: 'Modern Ruby on Rails screencasts',
                        keywords: 'ruby, rails, ruby-on-rails',
                        reverse: true, # app name at the end like `5 posts | SupeRails`
                        image: asset_url("logo.png"),
                        og: {
                          image: asset_url("logolong.png"),
                        }
                        icon: "/favicon.png", type: "image/png"
  %>
</head>
```

Override the default meta tags from a controller action with `set_meta_tags`:

```ruby
# app/controllers/posts_controller.rb
  def index
    set_meta_tags title: "#{Post.size} posts"
  end

  def show
    set_meta_tags title: @post.name,
                  description: @post.description,
                  keywords: @post.tags.pluck(:name).split(', ')
  end

   def new
     set_meta_tags title: "#{action_name.capitalize} #{controller_name.singularize}" # New post
   end
```

You can also customize the settings in a config file:

```ruby
# config/initializers/meta_tags.rb
MetaTags.configure do |config|
  config.title_limit = 200
  config.truncate_site_title_first = true
end
```

Example implementations:
* [insta2blog.com](https://github.com/yshmarov/insta2blog.com/commit/64d690a0e967027c87de13de8cb39113d28cf538){:target="blank"}
* [old SupeRails](https://github.com/yshmarov/superails-rails6/commit/d489756cc1f1b181e90f86c909d5ba9ce113ff1b){:target="blank"}

### Testing OpenGraph

ℹ️ [OpenGraph API](https://ogp.me) meta tags are used to improve the appearance and functionality of shared links on social media platforms

Use [Ngrok]({% post_url 2024-02-12-ngrok %}) to get a public URL to your localhost, and use a meta tag previe tool to test how your website renders.

Preview tools:

[opengraph.xyz](https://www.opengraph.xyz/url/https%3A%2F%2Fsuperails.com%2Fposts%2Frails-158-build-a-calendar-from-zero-no-external-dependencies) - VERY GOOD PREVIEW TOOL ✅

![meta-tags-opengraph](assets/images/meta-tags-opengraph-xyz.png)

[Facebook OG](https://developers.facebook.com/tools/debug/)

![meta-tags-facebook](assets/images/meta-tags-facebook.png)

[Linkedin OG](https://www.linkedin.com/post-inspector/inspect/https:%2F%2Fsuperails.com%2Fposts%2Frails-159-access-localhost-anywhere-with-ngrok)

![meta-tags-linkedin](assets/images/meta-tags-linkedin-post-inspector.png)

[Twitter OG cards docs](https://developer.twitter.com/en/docs/twitter-for-websites/cards/overview/abouts-cards). They have discontinued their preview tool. Log in, click on "create post", paste a link, and wait for it to render.

![meta-tags-twitter](assets/images/meta-tags-twitter.png)

### Final thoughts

💡 There are many tags and it can seem a bit overwhelming to set them all. First focus on the more important meta tags, than do the other ones.

💡 Open Graph image generator sounds like a good SaaS idea:

![alt text](assets/images/meta-tags-opengraph-generator.png)
