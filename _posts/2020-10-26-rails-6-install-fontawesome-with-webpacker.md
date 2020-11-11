---
layout: post
title: 'Rails 6: Install FontAwesome with Yarn and Webpacker'
author: Yaroslav Shmarov
tags: 
- fontawesome
- webpacker
- ruby on rails 6
thumbnail: https://www.drupal.org/files/project-images/font_awesome_logo.png
---

# **1. console:**

```
yarn add @fortawesome/fontawesome-free
```

# **2. javascript/packs/application.js:**

```
import "@fortawesome/fontawesome-free/css/all"
```

# **3. Check if it works:**

Add couple of icons in any .html.erb (view) file:
```
<i class="far fa-address-book"></i>
<i class="fab fa-github"></i>
```

That's it!😊

****

# **Relevant links:** 

* [see all FontAwesome Icons here](https://fontawesome.com/icons?d=gallery&m=free){:target="blank"}
* [Yarn package](https://yarnpkg.com/package/@fortawesome/fontawesome-free){:target="blank"}