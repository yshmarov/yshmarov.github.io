---
layout: post
title: 'Rails 6: Install Bootstrap with Yarn and Webpacker: Full guide'
author: Yaroslav Shmarov
tags:
- webpacker
- yarn
- bootstrap
- ruby on rails 6
- ruby on rails
thumbnail: /assets/thumbnails/bootstrap.png
---

[See TLDR version of this article]({% post_url 2020-10-12-rails-6-install-bootstrap-with-webpacker-tldr %})

There are many guides and many paths to make bootstrap available in Rails 6.

Having analyzed dosend of tutorials and production applications, below seems to be the most "correct" path.

In Rails 5 you would normally use [gem bootstrap](https://github.com/twbs/bootstrap-rubygem){:target="blank"} that would "download the bootstrap JS and CSS files.

As we are using webpacker in Rails 6, the right way is to download a package. Webpacker is fit to work with the "yarn package manager".

Bootstrap has an official [yarn package](https://classic.yarnpkg.com/en/package/bootstrap){:target="blank"}, meaning that it can be installed with a command like yarn add bootstrap (instead of installing a gem).

But bootstrap has some dependencies like jquery and popper.js that need to be installed too.

As well, in Rails 5 we used stylesheets in `app/assets/stylesheets/application.css`:

![stylesheet-path](/assets/2020-10-19-rails-6-install-bootstrap-with-webpacker-full/stylesheet-path.png)

And to tell our application to use this file, in application.html.erb in Rails 5 we added the line to application.html.erb:

= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload'

Now, we will be compiling the stylesheets inside the javascripts folder. 

# **Let's start:**

* In the `console` run the command:

```
yarn add jquery popper.js bootstrap
```

it will install the yarn packages that you need to run bootstrap.

* Now, in the file ~environment.js` add the following:

```
const { environment } = require('@rails/webpacker')
const webpack = require("webpack")
environment.plugins.append("Provide", new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    'window.jQuery': 'jquery',
    Popper: ['popper.js', 'default']
  }))
module.exports = environment
```

* Next, create a folder `app/javascript/stylesheets`. 

In the folder `app/javascript/stylesheets` create a new file `application.scss`:

![new-stylesheet-path](/assets/2020-10-19-rails-6-install-bootstrap-with-webpacker-full/new-stylesheet-path.png)

We will be placing all the css there.

* Make the `app/javascript/stylesheets` available in your `application.html.erb`. 

`application.html.erb` should look like this:

```
= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' 
= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' 
= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' 
```

Notice the `stylesheet_pack_tag`.

* Finally, in `application.js` we add

```
import 'bootstrap/dist/js/bootstrap'
import 'bootstrap/dist/css/bootstrap'
require("stylesheets/application.scss")
```

The first 2 "import" commands add the bootstrap JS and CSS that was imported by yarn.

The last "require" makes anything that you add in `app/javascript/stylesheets/application.scss` compile whenever you add a change to it.

6. Now you can add a piece of code like this in any view 

```
<span class="badge badge-secondary">Thanks Yaro! It works!</span> 
```

and it will add a Bootstrap badge.

Hooray! Bootstrap is installed!😊

P.S. If you will be adding actiontext, it's good to place it under `app/javascript/stylesheets/application.scss`:

`@import "./actiontext.scss";`

****

# **Relevant links**

* [see the official Bootstrap docs here](getbootstrap.com/){:target="blank"}
* [Bootstrap yarn package](https://classic.yarnpkg.com/en/package/bootstrap){:target="blank"}