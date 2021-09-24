
https://github.com/kpumuk/meta-tags


```
Rails.application.class.module_parent.name
```


<meta content="online education, course platform, video tutorials, udemy clone" name="keywords"/>
<meta content="Online Learning and Skill sharing platform" name="description"/>
<meta content="Yaroslav Shmarov" name="author"/>
<script src="https://js.stripe.com/v3/"></script>
<%= favicon_link_tag 'thumbnail.png' %>
<title>
  <%= content_for?(:title) ? yield(:title) : "Corsego" %>
</title>



<% content_for :title do %>
  <%= @course.title %>
<% end %>


####

gem meta tags


In layout:

<head>
  <%= display_meta_tags %>
  ...
</head>

In controller:

def show
  set_meta_tags title: "your title",
                keywords: "your keywords",
                description: "your description"
end


