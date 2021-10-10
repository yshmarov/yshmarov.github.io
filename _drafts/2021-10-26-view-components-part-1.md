---
layout: post
title: "ViewComponent - HOWTO"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails active-storage barcode
thumbnail: /assets/thumbnails/barcode.png
---

Imagine: you want to display a users avatar in many places across the app.

user.rb
```
def hero_image
  if avatar.present?
    avatar
  else
    'default image'
end
```

<%= image_tag user.hero_image %>

You can:
* extract `/_avatar.html.erb` into a partial.
* add a helper method in `app/helpers/users_helper.rb` for handling logic in the avatar partial.
* alternatively, you can use the `decorators` pattern and abstract the 
ViewComponent

Note to self

As of now I will be diving in much more into the frontend side of Rails and exploring Hotwire, ViewComponent, and Tailwind.

I will keep posting on all subjects.
Currently I have drafts for another 30+ posts, but again, it takes a lot of work to turn a draft into something that you are proud of.

Initially I started this blog as a "Note to self". I do return to my blog to look something up all the time!


* [Official View Components docs](https://viewcomponent.org/guide/getting-started.html)
* [Why View Components are better than partials](https://teamhq.app/blog/tech/17-how-rendering-partials-can-slow-your-rails-app-to-a-crawl)
* [Same author as above elaborates on why View Components are good](https://teamhq.app/blog/tech/15-introducing-viewcomponent-the-next-level-in-rails-views)


## LEVEL 1.

### Rails helpers way:

/superails/app/helpers/application_helper.rb
```
  def status_label(value)
    case value
    when 'draft'
      badge_color = 'badge bg-secondary'
    when 'published'
      badge_color = 'badge bg-success'
    when 'removed'
      badge_color = 'badge bg-danger'
    end
    content_tag(:span, value, class: badge_color)
  end
```

/app/views/posts/show.html.erb
```
    <%= status_label(post.status) %>
```

### ViewComponent way:

/app/components/boolean_label_component.rb
```
class BooleanLabelComponent < ViewComponent::Base
  def initialize(value:)
    @value = value
  end

  private

  def badge_color
    case @value
    when 'draft'
      badge_color = 'badge bg-secondary'
    when 'published'
      badge_color = 'badge bg-success'
    when 'removed'
      badge_color = 'badge bg-danger'
    end
  end
end
```

/app/components/boolean_label_component.html.erb
```
<%= content_tag(:span, content, class: badge_color) %>
```

/app/views/posts/show.html.erb
```
    <%= render(BooleanLabelComponent.new(value: post.status)) do %>
      <%= post.status %>
    <% end %>
```

`content` is what you yield in a block.

## LEVEL 2.


```
view component validation!; base component before render validate?
view component blocks
```
