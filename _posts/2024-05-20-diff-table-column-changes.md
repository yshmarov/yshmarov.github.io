---
layout: post
title: "Track change history of attributes and display diff"
author: Yaroslav Shmarov
tags: rails git diff frontend diffy audited
thumbnail: /assets/thumbnails/diff.png
youtube_id: 1rwKn0Figuo
---

There are lots of "text compare tools" online, some of them are even monetized.

![diff-rephrase](/assets/images/diff-rephrase.png)

For me as a developer, github is the most familiar tool for viewing the difference of a file before and after changes.

![diff-github-split-unufied](/assets/images/diff-github-split-unufied.gif)

Sometimes in a Rails app we want to track changes to attributes on a database table (how a `post.title` or `post.body` changed). Let's build this feature:

![audited-diff-column-split-views](/assets/images/audited-diff-column-split-views.gif)

Google Docs have a great implementation for change history:

![version control in google docs](/assets/images/version-control-google-sheets.png)

Here's how you can add version control and display changes in your app!

### Store changes

First, let's create a db table:

```sh
rails g scaffold post title:string body:text
```

Log all changes to a rails model with [**gem audited**](https://github.com/collectiveidea/audited)

```sh
bundle add audited
rails generate audited:install
rails db:migrate
```

Audit all changes on all attributes. You can also limit what is audited (check the official gem docs).

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  audited
end
```

Display change (audit) history:

```ruby
# app/views/posts/show.html.erb
Change count: <%= @post.audits.count %>

<% @post.audits.sort_by(&:version).reverse.each do |audit| %>
  <div style="border: 1px solid black; padding: 10px">

    <%= audit.action %>
    <%= audit.version %>
    <%= audit.created_at %>

    <% audit.audited_changes.each do |attribute, changes| %>
      <div>
        <b><%= attribute %></b>
        <% if changes.is_a? Array %>
          <%= changes[0], changes[1] %>
        <% elsif changes.is_a? String %>
          <%= changes %>
        <% end %>
      </div>
    <% end %>

  </div>
<% end %>
```

### Display changes

[**Diffy**](https://github.com/samg/diffy) is a library that creates diffs between strings in an HTML-friendly way. It's all you need to turn the difference between two strings into something that looks like GIT!

```
bundle add diffy
```

Update your views to use `Diffy` for the `changes`:

```ruby
# app/views/posts/show.html.erb
Change count: <%= @post.audits.count %>

<% if params[:split] == "true" %>
  <%= link_to 'Column view', post_path(@post) %>
<% else %>
  <%= link_to 'Split view', post_path(@post, split: true) %>
<% end %>

<% @post.audits.sort_by(&:version).reverse.each do |audit| %>
  <div style="border: 1px solid black; padding: 10px">

    <%= audit.action %>
    <%= audit.version %>
    <%= audit.created_at %>

    <% audit.audited_changes.each do |attribute, changes| %>
      <div>
        <b><%= attribute %></b>
        <% if changes.is_a? Array %>
          <% if params[:split] %>
            <div style="display: flex">
              <%= Diffy::SplitDiff.new(changes[0], changes[1], format: :html).left.html_safe %>
              <%= Diffy::SplitDiff.new(changes[0], changes[1], format: :html).right.html_safe %>
            </div>
          <% else %>
            <%= Diffy::Diff.new(changes[0], changes[1], include_plus_and_minus_in_html: true, include_diff_info: true).to_s(:html).html_safe %>
          <% end %>
        <% elsif changes.is_a? String %>
          <%= Diffy::Diff.new("", changes, include_plus_and_minus_in_html: true).to_s(:html).html_safe %>
        <% end %>
      </div>
    <% end %>

  </div>
<% end %>
```

Finally, run `Diffy::CSS` to generate CSS that you can paste into your `application.css`:

```css
/* app/assets/stylesheets/application.css */
.diff{overflow:auto;}
.diff ul{background:#fff;overflow:auto;font-size:13px;list-style:none;margin:0;padding:0;display:table;width:100%;}
.diff del, .diff ins{display:block;text-decoration:none;}
.diff li{padding:0; display:table-row;margin: 0;height:1em;}
.diff li.ins{background:#dfd; color:#080}
.diff li.del{background:#fee; color:#b00}
.diff li:hover{background:#ffc}
/* try 'whitespace:pre;' if you don't want lines to wrap */
.diff del, .diff ins, .diff span{white-space:pre-wrap;font-family:courier;}
.diff del strong{font-weight:normal;background:#fcc;}
.diff ins strong{font-weight:normal;background:#9f9;}
.diff li.diff-comment { display: none; }
.diff li.diff-block-info { background: none repeat scroll 0 0 gray; }
```

Final result - normal view:

![audited-diff-column](/assets/images/audited-diff-column.png)

Final result - split view:

![audited-diff-split](/assets/images/audited-diff-split.png)

[Code example on github](https://github.com/corsego/diff-app/commit/10204bbb8c68333749980f1917b22b14afb6b51f)

That's it! Now you can log all your changes and display change history in a readable way! 🤠
