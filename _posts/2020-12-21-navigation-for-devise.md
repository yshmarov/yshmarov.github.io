---
layout: post
title:  Memo on navigation links when using gem devise
author: Yaroslav Shmarov
tags: 
- ruby on rails
- devise
thumbnail: https://2.bp.blogspot.com/-zLeLuzX5ux0/WTUO8RYuiNI/AAAAAAAABAs/eDXmy0SxobYLVmrrQU_jytpYTlaByyrzwCLcB/s400/authentication-crash-course-with-devise.png
---

When installing `gem devise` for a `User` model, add these links to your application:

Basic navigation links:
```
<% if current_user %>
  <%= link_to current_user.email, edit_user_registration_path %>
  <%= link_to "Log out", destroy_user_session_path, method: :delete %>
<% else %>
  <%= link_to "Log in", new_user_session_path %>
  <%= link_to "Register", new_user_registration_path %>
<% end %>
```

or a Navbar with bootstrap:
```
<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <a class="navbar-brand" href="/">
    <i class="fas fa-flag"></i>
    Brand
  </a>
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
    <span class="navbar-toggler-icon"></span>
  </button>
  <div class="collapse navbar-collapse" id="navbarSupportedContent">
    <ul class="navbar-nav mr-auto">
      <%= link_to root_path, class: "nav-link #{'active font-weight-bold' if current_page?(root_path)}" do %>
        <div class="fa fa-home"></div>
        Home
      <% end %>
    </ul>
    <ul class="navbar-nav mr-right">
      <% if current_user %>
        <li class="nav-item dropdown">
          <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            <div class="fa fa-user"></div>
            <b><%= current_user.email %></b>
          </a>
          <div class="dropdown-menu" aria-labelledby="navbarDropdown">
            <%= link_to edit_user_registration_path, class: "dropdown-item #{'active font-weight-bold' if current_page?(edit_user_registration_path)}" do %>
              <div class="fa fa-cog"></div>
              <b>Account settings</b>
            <% end %>
            <%= link_to destroy_user_session_path, method: :delete, class: "dropdown-item" do %>
              <div class="fa fa-sign-out-alt"></div>
              <b>Sign out</b>
            <% end %>
          </div>
        </li>
      <% else %>
        <%= link_to "Log in", new_user_session_path, class: "nav-link #{'active font-weight-bold' if current_page?(new_user_session_path)}" %>
        <%= link_to "Sign up", new_user_registration_path, class: "nav-link #{'active font-weight-bold' if current_page?(new_user_registration_path)}" %>
      <% end %>
    </ul>
  </div>
</nav>
```