---
layout: post
title: "Search field without gems"
author: Yaroslav Shmarov
description: find records that contain text
tags: ruby rails ruby-on-rails search
thumbnail: /assets/thumbnails/search.png
---

### MISSION: field to search for user email that **contains** characters

![search-field.png](/assets/ruby-on-rails-search-field-without-gems/search-field.png)

users_controller.rb
```
  def index
    if params[:email]
      @users = User.where('email ILIKE ?', "%#{params[:email]}%").order(created_at: :desc) #case-insensitive
    else
      @users = User.all.order(created_at: :desc)
    end
  end
```
any view (users/index.html.erb or in a **bootstrap** navbar)
```
.form-inline.my-2.my-lg-0
  = form_tag(courses_path, method: :get) do
    .input-group
      = text_field_tag :title, params[:title], autocomplete: 'off', placeholder: "Find a course", class: 'form-control-sm'
      %span.input-group-append
        %button.btn.btn-primary.btn-sm{:type => "submit"}
          %span.fa.fa-search{"aria-hidden" => "true"}
```
without bootstrap
```
<%= form_tag(users_path, method: :get) do %>
  <%= text_field_tag :email, params[:email], autocomplete: 'off', placeholder: "user email" %>
  <%= submit_tag "Search" %>
<% end %>
```
