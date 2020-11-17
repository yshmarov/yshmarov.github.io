---
layout: post
title: "Rails 6: Turn your app into a PWA with Webpacker: TLDR"
author: Yaroslav Shmarov
tags: 
- ruby on rails
- pwa
- progressive-web-app
- webpacker
thumbnail: https://skalfa.com/wp-content/uploads/2018/11/pwa1.png
---

* Create a manifest.json
* Create service_workers
* 
    <link rel="manifest" href="/manifest.webmanifest">
    <link rel="manifest" href="manifest.json" crossorigin="use-credentials">
    <script type="module" src="my.js" crossorigin></script>


* Based on [this article](https://dev.to/coorasse/the-progressive-rails-app-46ma){:target="blank"}
* [Yarn webpacker-pwa](https://yarnpkg.com/package/webpacker-pwa){:target="blank"}
https://medium.com/@benmiriello_36460/amadeus-api-part-3-fff3c12e46cc
https://googlechrome.github.io/samples/service-worker/custom-offline-page/

https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Add_to_home_screen