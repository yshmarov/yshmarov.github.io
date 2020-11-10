---
layout: post
title: 'Ruby on Rails: Highlight link_to current_page'
author: Yaroslav Shmarov
tags:
- bootstrap
- ruby on rails
- html
thumbnail: https://lh3.googleusercontent.com/-3myWBVywfWk/X49GkDG0nqI/AAAAAAACE-s/uiyKk3TWDqM6STuB1F3AZ2BwSUkEef8aACLcBGAsYHQ/s72-w128-c-h310/image.png
---

Often to improve your navigation UI (user experience), you will want to mark the link to current page "active":

![2020-10-27-ruby-on-rails-highlight-linkto-current-page.png](/assets/2020-10-27-ruby-on-rails-highlight-linkto-current-page/2020-10-27-ruby-on-rails-highlight-linkto-current-page.png)

the simple way to do it (assuming a bootstrap navbar):

{% highlight ruby %}
<li class="<%= 'active font-weight-bold' if current_page?(root_path) %> nav-item">
  <%= link_to "Homepage", root_path, class: 'nav-link' %>   
</li>
{% endhighlight %} 

or if you want to add some fancy fontawesome:

{% highlight ruby %}
<li class="<%= 'active font-weight-bold' if current_page?(root_path) %> nav-item">
  <%= link_to root_path, class: 'nav-link' do %>
    <i class="fa fa-home"></i>
    Homepage
  <% end %>
</li>
{% endhighlight %} 

however when you have a lot of links, your code will look "dirty".

To make it look cleaner, you can add the following lines to `application_helper.rb`:

{% highlight ruby %}
def active_link_to(name, path)
    content_tag(:li, class: "#{'active font-weight-bold' if current_page?(path)} nav-item") do
      link_to name, path, class: "nav-link"
    end
  end 
end 

def deep_active_link_to(path)
  content_tag(:li, class: "#{'active font-weight-bold' if current_page?(path)} nav-item") do
    link_to path, class: "nav-link" do
      yield
    end
  end 
end 
{% endhighlight %} 

this way you can write links like this

{% highlight ruby %}
<%= active_link_to "homepage" root_path %>
{% endhighlight %} 

or 

{% highlight ruby %}
<%= deep_active_link_to root_path do %>
  <i class="fa fa-home"></i>
  Homepage 
<% end %>
{% endhighlight %} 
