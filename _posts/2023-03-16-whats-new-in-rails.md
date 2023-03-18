---
layout: post
title:  What's the difference between Rails 4, Rails 5, Rails 6 and Rails 7?
author: Yaroslav Shmarov
tags: ruby-on-rails
thumbnail: /assets/thumbnails/rails-logo.png
---

I started working with Ruby on Rails around 2015, when Rails 4 was the lastest version. Here I want to share some of the main highlights that have most affected the way I write code over the years of Rails evolution.

### Rails 4

When Rails 4 was released, there was one major change in the way you write backend for your app in comparison to Rails 3: strong parameters have been introduced. This allows you to securely define which parameters of a model can be updated **on a controller level** with this kind of syntax: `params.require(:task).permit(:title, :project_id, :user_id)`.

When writing frontend, there were some strange obstacles:
- Turbolinks did not work well with javascript and JS libraries, and you would be disabling them by default in many Rails apps. In 
- Everybody was using "AJAX" and `*.js.erb` templates for server-side rendering frontend updates. In the future this evolved into Hotwire Turbo Streams.
- jQuery was everywhere. You would rarely write vanilla JS. Most external JS libraries would require jQuery.
- Coffeescript was somewhat used, but I managed to avoid learning it. 
- You would use gems to import CSS and JS packages, instead of NPM or YARN. The gems were not so well maintained as the NPM or YARN packages. For example, you would use a gem to import the CSS and JS for Bootstrap, and it would require some jQuery set up for popovers to work nicely.

### Rails 5

I was very excited for the release of Rails 5. It came with new core libraries:
- ActionText, a WYSIWYG rich text editor that was abstracted from Basecamp. There was no more need to look for sketchy ways to implement a nice text editor in your Rails app.
- ActiveStorage, a tool to easily attach files to ActiveRecord objects and store them on the cloud, like AWS S3. No more need for Paperclip or Carrierwave gems. 
- ActionCable for establishing Websocket connections. I didn't understand it and use it much at the time.

Rails is an opinionated framework, so you don't have to waste time on making some decisions!

### Rails 6

Ruby on Rails has always been considered slightly more of a backend framework, and backend developers don't care to learn about the crazy world of compiling Javascript and CSS in an app. The "gem to use a JS library" apprach was not sustainable, and the world had moved on. To stay relevant for building frontend applications, Rails needed a better way of importing external CSS and JS packages.

So, Webpacker was introduced. It allowed you do import JS/CSS packages from YARN. You could run something like `yarn add @popperjs/core`. Webpacker came with it's own problems, but it was a real breakthrough. All the libraries like "gem bootstrap" became irrelevant, because now you could import frontend libraries [directly from the source]({% post_url 2021-04-26-rails-bootstrap-5-yarn %}).

Gems like [`rubyconfig/config`](https://github.com/rubyconfig/config) were replaced by [`config_for`]({% post_url 2021-07-16-rails-settings-config-for %}).

Gems for encrypting secrets were replaced by [Rails Credentials]({% post_url 2020-12-07-ruby-on-rails-6-credentials-tldr %})

### Rails 7

Gems for encrypting database table attributes like [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted) got replaced with [Active Record Encryption](https://edgeguides.rubyonrails.org/active_record_encryption.html).

Not so many changes in the backend, but a lot of changes to the frontend!

Webpacker was good for it's time. A nessesary evil. Now, the frontend has evolved and Rails 7 offers new approaches to importing new JS packages out of the box: **Importmaps** and **JS/CSS bundling**. Importmaps is default in new Rails apps, but it can have troubling importing CSS; this technology is still developing. JS/CSS bundling very good and used in most projects.

Also when generating a new Rails app you can have BootstrapCSS or TailwindCSS installed out of the box. No more wasting time on that!

Turbolinks is replaced with Hotwire/Turbo, that is easier to configure behaviours for. However specifying responce formats became more important, and one of the most popular gems - Devise, was hard to work with for a while. So, you had to disable turbo on all Devise forms and buttons. It is fixed now.

A "breaking change" was the depreciation of `rails-ujs`, that allowed `link_to` that is a DSL for html `<a>` tag to do non-GET requests. Now the best practice is to use `button_to` for non-GET requests (`POST`, `PUT`, `PATCH`, `DELETE`).

Hotwire/TurboStreams became default for AJAX server-side rendering. `*.js.erb` format was replaced with `*.turbo_stream.erb`. It became very easy to serve content without refreshing or redirecting.

Hotwire/TurboStreamBroadcasts use ActionCable to do server-side rendering for all clients listening to the same channel. This made building live functionality (like live chat) very easy.

StimulusJS is now the default way of writing Javascript for Rails. As of now, `<script>` tags are frowned upon.

### Conclusion

Overall, since Rails 4 there have been few changes on the already solid backend architecture, but many changes in the always-evolving frontend.

When upgrading Rails versions, the biggest challenge is updating the frontend. You should also be sure that the gems you used in the old version are still maintained; core features of some gems have been integrated into the Rails framework.

P.S. Did I miss something important?
