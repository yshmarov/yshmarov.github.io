---
layout: post
title: "Accept cookies consent banner in Rails"
author: Yaroslav Shmarov
tags: ruby-on-rails gdpr cookies
thumbnail: /assets/thumbnails/gdpr-cookie.png
youtube_id: Udkil4287pM
---

According to GDPR regulations you might need to add a banner on your site where a website visitor can `accept`/`reject` cookies.

A basic cookies modal can look like this:

![rails-cookies.gif](/assets/images/rails-cookies.gif)

We can store this decision in `session[:cookies_accepted]`.

If a user **accepts** - expect normal website behavior.

If a user **rejects** - you might want to disable some tracking services:

```ruby
<%= render "shared/google_analytics" if (session[:cookies_accepted] == true) %>
```

### HOWTO

Generate `views`, `controllers`, `routes` for our cookies:

```shell
# Terminal
rails g controller cookies index
```

* Render the cookies view inside a `turbo_frame_tag`;
* Display links to `accept`/`reject` modals:

```ruby
# app/views/shared/cookies_banner.html.erb
<%= turbo_frame_tag :cookies_modal do %>
  <% if session[:cookies_accepted].nil? # don't re-render if a true/false selected %>
    <section class="cookies-modal">
      <h3>We process cookies.</h3>
      <%= link_to "Accept cookies", cookies_path(cookies: true), method: :post %>
      <%= link_to "Reject cookies", cookies_path(cookies: false), method: :post %>
    </section>
  <% end %>
<% end %>
```

Positioning the modal with css:

```css
/* app/assets/stylesheets/application.css */
.cookies-modal {
  position: absolute;
  padding: 0.5rem;
  z-index: 2;
  left: 0.5rem;
  bottom: 0.5rem;
  min-width: 50%;
  max-width: 24rem;
  word-break: break-word;
  border-radius: 6px;
  background: #bad5ff;
}
```

A simplistic route:

```ruby
# config/routes.rb
  get 'cookies', to: 'cookies#index' 
```

Display cookies template, update preferences based on selected accept/reject params:

```ruby
# app/controllers/cookies_controller.rb
  def index
    session[:cookies_accepted] = params[:cookies] if params[:cookies]
  end
```

Finally, to make the cookies modal visible in the app, **conditionally** display a `turbo_frame` pointing to the `cookies_banner` in the layout, if the cookies `true`/`false` has not yet been selected:

```ruby
# app/views/application.html.erb
<%= session[:cookies_accepted] # display selected value for testing purposes %>
<%= turbo_frame_tag :cookies_modal, src: cookies_path if session[:cookies_accepted].nil? %>
```

P.S. for setting `session[:cookies_accepted]` to `nil` and re-testing the above, you can simply add the below line to any #GET controller action in your app and visit the page:

```diff
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
+    session[:cookies_accepted] = nil
  end
end
```

That's it!

Alternatively, there are some cookies/GDPR gems:
* [`infinum/cookies_eu`](https://github.com/infinum/cookies_eu) - Gem to add cookie consent to Rails application
* [`prey/gdpr_rails`](https://github.com/prey/gdpr_rails) - Rails Engine for the GDPR compliance 
* [`osano/cookieconsent`](https://github.com/osano/cookieconsent) - A free solution to the EU, GDPR, and California Cookie Laws
