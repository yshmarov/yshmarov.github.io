---
layout: post
title: "Ruby on Rails 6: Disappearing flash messages with toastr"
author: Yaroslav Shmarov
tags: ruby-on-rails jsonb store_accessor
thumbnail: /assets/thumbnails/notification.png
---

![flash-message-example](/assets/2020-12-29-flash-messages-with-toastr-js/flash-message-example.png)

Source: 
[https://github.com/CodeSeven/toastr](https://github.com/CodeSeven/toastr){:target="blank"}

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
customizing the flash:
```
<% unless flash.empty? %>
  <script type="text/javascript">
    <% flash.each do |f| %>
        <% type = f[0].to_s.gsub('alert', 'error').gsub('notice', 'info') %>
        toastr['<%= type %>']('<%= f[1] %>', '', {"closeButton": true,
                                                  "positionClass": "toast-top-center", 
                                                  "onclick": null, 
                                                  "showDuration": "300", 
                                                  "hideDuration": "1000", 
                                                  "timeOut": "5000", 
                                                  "extendedTimeOut": "1000", 
                                                  "showEasing": "swing", 
                                                  "hideEasing": "linear", 
                                                  "showMethod": "fadeIn", 
                                                  "progressBar": true,
                                                  "hideMethod": "fadeOut" });
    <% end %>
  </script>
<% end %>
```

Footnote: `require("stylesheets/application.scss")` = `import "../stylesheets/application"`
