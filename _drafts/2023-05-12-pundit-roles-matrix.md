---
layout: post
title: "Pundit Authorization: Access Rights Matrix"
author: Yaroslav Shmarov
tags: ruby-on-rails pundit authorization roles
thumbnail: /assets/thumbnails/stop-sign.png
---

```ruby
# app/models/user.rb
  enum role: {
    admin: "admin",
    moderator: "moderator",
    viewer: "viewer"
  }
```

```ruby
<table>
  <thead>
    <tr>
      <th>Roles</th>
      <% User.roles.each do |key, value| %>
        <th>
          <label for="<%= value %>">
            <%= radio_button_tag 'user[role]', value, value == @user.role, id: value %>
            <%= key %>
          </label>
        </th>
      <% end %>
    </tr>
  </thead>
  <tbody>
    <% policy_list = [PostPolicy, UserPolicy] %>
    <% policy_list.each do |policy| %>
      <% policy.instance_methods(false).each do |method| %>
        <tr>
          <td>
            <%= policy.to_s.sub("Policy", "") %>
            <%= method %>
          </td>
          <% User.roles.each do |key, value| %>
            <td>
              <% user = User.new(role: value) %>
              <%= policy.to_s.constantize.new(user, user).send(method) ? "✅" : "⛔️" %>
            </td>
          <% end %>
        </tr>
      <% end %>
    <% end %>
  </tbody>
</table>
```

