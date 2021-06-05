---
layout: post
title:  Write skinny scaffolds and generators
author: Yaroslav Shmarov
tags: ruby-on-rails
thumbnail: https://previews.123rf.com/images/dmitrymoi/dmitrymoi1609/dmitrymoi160900126/63675567-man-before-and-after-sports-cartoon-vector-illustration-diet-and-sport-fat-and-strong-character-fitn.jpg
---

**TLDR:** add a few `--no` tags to your rails generators to produce only the crucial files:

`rails g controller home index --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework`

`rails g scaffold product name description:text --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder`

****

Now, Let's dive in and make our rails generators cleaner!

# **Skinny Scaffold Generator**

A usual scaffold like 
```
rails g scaffold product name description:text
``` 
produces:

* Migration
* Model
* View
* Controller
* Tests
* Helpers
* Stylesheets
* jbuilder

![dirty scaffold](/assets/2020-11-09-skinny-rails-generators/dirty scaffold.png)

That's a lot! However you won't be needing most of these in most hobby applications. 

A shorter scaffold would be:

```
rails g scaffold product name description:text --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
```
that produces:

* Migration
* Model
* View
* Controller

![clean scaffold](/assets/2020-11-09-skinny-rails-generators/clean scaffold.png)

Much cleaner! Bravo!

# **Skinny Controller Generator**

A usual command like 
```
rails g controller home index
```
produces:

* Controller
* Views
* Helper
* Stylesheet
* Tests

![dirty controller generator](/assets/2020-11-09-skinny-rails-generators/dirty controller generator.png)

That's a lot! And you won't need most of it for a basic hobby app! 

Let's modify our generator and run:

```
rails g controller home index --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework
```
That produces only:

* Controller
* Views

![clean controller generator](/assets/2020-11-09-skinny-rails-generators/clean controller generator.png)

Much cleaner, and does not create mess that you will likely not be using!

****

# **Relevant links**

* [Official docs - Creating and Customizing Rails Generators & Templates](https://guides.rubyonrails.org/generators.html){:target="blank"}

`rails g scaffold product name description:text`

`rails g scaffold product name description:text --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder `

