---
layout: post
title: "Migrating from Bootstrap 4 with Bootstrap 5"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails markdown
thumbnail: /assets/thumbnails/bootstrap.png
---

Some main changes from my experience:

### 1. Quick find and replace

* replace `badge badge` with `badge bg`
* replace `jumbotron` with `card bg-light`
* replace `card-deck` with `row row-cols-1 row-cols-md-2 g-4` or `card-group`
* replace `form-group` with `mb-3`
* replace `font-weight` with `fw`

### 2. Replace all dropdowns with bootstrap 5 dropdown code, **including navbar**

### 3. Margins

`left` and `right` replaced with something like `start` and `end`.
Meaning, we would have `<ul class="navbar-nav me-auto">` and `<ul class="navbar-nav me-auto">` for navbar-end (right) and navbar-start (left)

### Surely, there's more but these are the basics to get it working :)
