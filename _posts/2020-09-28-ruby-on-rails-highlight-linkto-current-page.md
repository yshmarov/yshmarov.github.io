---
layout: post
title: 'Highlight link to current page'
author: Yaroslav Shmarov
tags:
- ruby on rails
- html
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: yvB2ZQh1HVY
---

Often to improve your navigation UI (user experience), you will want to mark the link to current page "active":

![2020-10-27-ruby-on-rails-highlight-linkto-current-page.png](/assets/2020-10-27-ruby-on-rails-highlight-linkto-current-page/highlight-active-link-to-current-page.png)

### 2024 Update

Active link_to where that has `font-bold underline` assigned as default `active_classes`. You can override them by manually setting `active_classes`.

```ruby
# app/helpers/application_helper.rb
  def active_link_to(text = nil, path = nil, active_classes: '', **options, &)
    path ||= text

    classes = active_classes.presence || 'font-bold underline'
    options[:class] = class_names(options[:class], classes) if current_page?(path)

    return link_to(path, options, &) if block_given?

    link_to text, path, options
  end
```

Test all scenarios:

```ruby
# test/helpers/application_helper_test.rb
require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'active_link_to' do
    def current_page?(link)
      true
    end

    assert_equal(
      active_link_to('Home', root_path),
      link_to('Home', root_path, class: 'font-bold underline')
    )

    assert_equal(
      active_link_to(root_path) { 'Home' },
      link_to(root_path, class: 'font-bold underline') { 'Home' }
    )

    # override the default active classes
    assert_equal(
      active_link_to('Home', root_path, active_classes: 'bg-rose-400', class: 'foo'),
      link_to('Home', root_path, class: 'foo bg-rose-400')
    )

    def current_page?(link)
      false
    end

    assert_equal(
      active_link_to('Home', root_path),
      link_to('Home', root_path)
    )

    assert_equal(
      active_link_to(root_path) { 'Home' },
      link_to(root_path) { 'Home' }
    )
  end
end
```

### 2023 Update

Use `active_link_to` instead of `link_to` to apply classes `underline font-bold` to links in your app.

```ruby
# app/helpers/application_helper.rb
  def active_link_to(text = nil, path = nil, **options, &)
    link = block_given? ? text : path

    options[:class] = class_names(options[:class], 'underline font-bold') if current_page?(link)

    if block_given?
      link_to(link, options, &)
    else
      link_to text, path, options
    end
  end
```

`class_names` that we are using was [introduced in Rails 6.1](https://www.bigbinary.com/blog/rails-6-1-introduces-class_names-helper)

`active_link_to` works with both inline `link_to` and block:

```ruby
<%= active_link_to "Posts", posts_path %>

<%= active_link_to posts_path do %>
  Posts
<% end %>
```

Writing tests for `active_link_to`:

```ruby
# test/helpers/application_helper_test.rb
class ApplicationHelperTest < ActionView::TestCase
  test 'active_link_to' do
    def current_page?(link)
      true
    end

    assert_equal(
      active_link_to('Home', static_pages_pricing_path),
      link_to('Home', static_pages_pricing_path, class: "active")
    )

    def current_page?(link)
      false
    end

    assert_equal(
      active_link_to('Home', static_pages_pricing_path),
      link_to('Home', static_pages_pricing_path)
    )
  end
end
```

### Original approach:

The simple way to do it (assuming a bootstrap navbar):

{% highlight ruby %}
<li class="<%= 'active fw-bold' if current_page?(root_path) %> nav-item">
  <%= link_to "Homepage", root_path, class: 'nav-link' %>   
</li>
{% endhighlight %} 

or if you want to add some fancy fontawesome:

{% highlight ruby %}
<li class="<%= 'active fw-bold' if current_page?(root_path) %> nav-item">
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
    content_tag(:li, class: "#{'active fw-bold' if current_page?(path)} nav-item") do
      link_to name, path, class: "nav-link"
    end
  end 
end 

def deep_active_link_to(path)
  content_tag(:li, class: "#{'active fw-bold' if current_page?(path)} nav-item") do
    link_to path, class: "nav-link" do
      yield
    end
  end 
end 

def deep_active_link_to_dropdown_item(path)
  content_tag(:li) do
    link_to path, class: "#{'active fw-bold' if current_page?(path)} dropdown-item" do
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
