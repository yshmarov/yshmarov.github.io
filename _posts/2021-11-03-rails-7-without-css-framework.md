---
layout: post
title: "Basic CSS for new Rails projects without a CSS Framework"
author: Yaroslav Shmarov
tags: ruby-on-rails css
thumbnail: /assets/thumbnails/css.png
---

Sometimes I don't want to burden a Rails app with a CSS framework.

Here are a few lines of CSS that I add to new Rails apps that leverage rails 7 scaffold templates.

app/assets/application.css
```css
/* display turbo frame - good for development */
turbo-frame {
  display: block;
  border: 1px solid blue;
}

/* error messages */
#error_explanation {
  color: red;
  border-radius: 6px;
  border: 2px solid red;
  padding: 6px;
  margin-bottom: 5px;
}

/* scaffold partial like inboxes/_inbox.html.erb */
.scaffold_record {
  border-radius: 6px;
  border: 2px solid #a3a3a3;
  padding: 6px;
  word-wrap: break-word;
  margin-bottom: 5px;
}

/* default flash message */
#notice {
  border-radius: 6px;
  padding: 6px;
  color: white;
  background: green;
}

/* center content, max width */
body {
  margin: 0 auto;
  max-width: 500px;
  display: block;
}

/* a new default font */
html, body {
  font-family: sans-serif;
  background-color: rgb(247, 250, 252);
}

/* to not always have links highlighted (often comes with bootstrap) */
a:link { text-decoration:none; }
a { text-decoration: none; }
```

Next step - [adding some CSS for the form inputs](https://www.w3schools.com/css/css_form.asp){:target="blank"}

You can also add a bottom footer [like this](https://blog.corsego.com/footer-bottom-of-page){:target="blank"}

Other things I do when setting up a new Rails project:
* `rails g controller static_pages landing_page pricing privacy terms`
* shared folder for `errors`, `flash`, `footer`, `navigation`
