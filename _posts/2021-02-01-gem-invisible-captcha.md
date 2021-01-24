---
layout: post
title: "Install and use gem invisible_captcha with devise"
author: Yaroslav Shmarov
tags: ruby-on-rails devise invisible_captcha
thumbnail: /assets/thumbnails/invisiblecaptcha.png
---

Quick guide to add [gem invisible_captcha](https://github.com/markets/invisible_captcha){:target="blank"} to your devise registrations.

Why? For fewer bots to sign up!

Final result:

![captcha1](/assets/gem-invisible-captcha/captcha1.png)

![captcha2](/assets/gem-invisible-captcha/captcha2.png)

HOWTO

gemfile:
```
gem 'invisible_captcha'
```
console:
```
bundle
rails g devise:controllers users -c=registrations
```
app/controllers/users/registrations_controller.rb
```
class Users::RegistrationsController < Devise::RegistrationsController
  invisible_captcha only: [:create]
```
routes.rb:
```
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
```
app/views/devise/registrations/new.html.erb, inside the form:
```
<%= invisible_captcha %>
```

[Alternative wiki to install Google REcaptcha gem](https://github.com/heartcombo/devise/wiki/How-To:-Use-Recaptcha-with-Devise){:target="blank"}
