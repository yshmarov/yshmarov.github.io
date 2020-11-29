---
layout: post
title: 'Ruby on Rails: templates and generators in 2020'
author: Yaroslav Shmarov
tags:
- ruby on rails
- templates
- generators
- boilerplates
thumbnail: /assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/templates-generators-logo.png
---

![templates-generators-logo.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/templates-generators-logo.png)

# Reinventing the wheel does not make sense..

Every time when you start a new rails project you have to repeat everything over again:

* install devise
* add Stimulus/React/Vue
* add Boostrap/Tailwind
* add FontAwesome
* configure ActiveStorage
* configure ActionMailer
* connect sendgrid/mailgun
AND THE LIST GOES ON...

There are 2 kinds of solutions solving this problem:

* Generators - run a script to install a certain feature
* Boilerplate apps - clone an app with pre-configured defaults

Below are the most prominent ones

# **1. Generators**

# [Railsnew.io](https://railsnew.io/){:target="blank"}

![railsnew-io.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/railsnew-io.png)

when creating a new app you usually run

```
rails new myappname
```

But there are so many options! 

Maybe you want something like

`rails new myappname --skip-spring --skip-listen --skip-bootsnap --skip-gemfile --skip-git --skip-keeps --skip-bundle --skip-puma --skip-action-text --skip-active-storage --skip-action-cable --skip-action-mailer --skip-action-mailbox --skip-sprockets --skip-javascript --skip-turbolinks --skip-webpack-install --skip-yarn --skip-test --skip-system-test `

This app provides a great UI to set up your new Rails app as you like!

****

# [Rubidium.io](https://www.rubidium.io/){:target="blank"}

![rubidium.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/rubidium.png)

run a command like 

```
rails app:template LOCATION=https://www.rubidium.io/templates/bootstrap-v4/consume
```

to install bootstrap. 

No gems or installation required. 

The website contains lots of different templates to install different gems and features. 

Built by the Driftingruby author.

****

# [Railsbytes.com](railsbytes.com/){:target="blank"}

![railsbytes.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/railsbytes.png)

great, just like above! Run a command like 

rails app:template LOCATION='https://railsbytes.com/script/x9Qsqx'
to install bootstrap. No gems or installation required. It's easy to contribute and add your own template to the list! Built by Chris from Gorails.

****

# [boring generators gem](https://github.com/abhaynikam/boring_generators){:target="blank"}

![boring-generators.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/boring-generators.png)

a new gem containing different templates, that you install into the development environment. 

Run a command like `rails generate boring:bootstrap:install` to install bootstrap. 

This project is good in comparison to the ones above, because it is completely open source.

Of course, all the solutions above are built based on the official Rails Application Templates and Rails Generators docs, that are definitely worth exploring:

![official-docs.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/official-docs.png)

****

# **2. Boilerplate apps**

# [RailsApps](http://railsapps.github.io/){:target="blank"}

![rails-composer.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/rails-composer.png)

one of the first boilerplates you find as a RoR developer. 

OUTDATED and NOT RECOMMENDED for new projects.

****

# [Suspenders](https://github.com/thoughtbot/suspenders){:target="blank"}

![suspenders.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/suspenders.png)

well maintained boilerplate with a lot of pre-configured defaults. 

****

# [Jumpstart](https://github.com/excid3/jumpstart){:target="blank"}

![jumpstart.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/jumpstart.png)

an up-to-date boilerplate with good docs and a vibrant community. Source code worth studying.

****

# [limestone](https://github.com/archonic/limestone){:target="blank"}

![limestone.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/limestone.png)

Rails 6 boilerplate with schema-level multitenancy, Stimulus, Docker

****

# And many more! Like [rails_6_github_template](https://github.com/davidteren/rails_6_github_template){:target="blank"}

![rails6-github-template-david-teren.png](/assets/2020-10-21-ruby-on-rails-templates-and-generators-2020/rails6-github-template-david-teren.png)

very fresh Rails 6 boilerplate with Stimulus, Tailwind and more.

****

### 2020 is a being a very rich year for the development of competitive Ruby on Rails boilerplates and generators. What can I say, it's a great community!

Special thanks to the authors of the above projects:
* [TrinityTakei](https://twitter.com/TrinityTakei){:target="blank"}
* [abhaynikam13](https://twitter.com/abhaynikam13){:target="blank"}
* [excid3](https://twitter.com/excid3){:target="blank"}
* [kobaltz](https://twitter.com/kobaltz){:target="blank"}
* [regardingaudio](https://twitter.com/regardingaudio){:target="blank"}
* [thoughtbot](https://twitter.com/thoughtbot){:target="blank"}