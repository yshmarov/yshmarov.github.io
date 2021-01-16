---
layout: post
title: "Ruby on Rails 6: Disappearing flash messages with toastr"
author: Yaroslav Shmarov
tags: ruby-on-rails jsonb store_accessor
---

![flash-message-example](/assets/2020-12-29-flash-messages-with-toastr-js/flash-message-example.png)

Source: 
[https://github.com/CodeSeven/toastr](https://github.com/CodeSeven/toastr)

console:
```
yarn add toastr
```
Import toastr in app/javascripts/packs/application.js:
```
global.toastr = require("toastr")
```
app/javascript/stylesheets/application.scss:
```
@import 'toastr'
```
app/javascript/packs/application.js:
```
import "../stylesheets/application"
```
app/views/layouts/application.rb:
```
<% unless flash.empty? %>
   <script type="text/javascript">
      <% flash.each do |f| %>
    <% type = f[0].to_s.gsub('alert', 'error').gsub('notice', 'info') %>
   	 toastr['<%= type %>']('<%= f[1] %>');
   <% end %>
   </script>
<% end %>
```
Footnote: `require("stylesheets/application.scss")` = `import "../stylesheets/application"`
