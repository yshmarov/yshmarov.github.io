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

## Part 1. Add a manifest

* Console:

```
echo > public/manifest.json
mkdir public/images
```

* Generate different sizes for your application logo 

[here - realfavicongenerator](https://realfavicongenerator.net/){:target="blank"}

[or here - simicart](https://www.simicart.com/manifest-generator.html){:target="blank"}

* Place the generated logos in `app/public/icons` folder.

* Add this to `layouts/application.html.erb` inside `<head>` tag:

```
<link rel="manifest" href="/manifest.json">
```

* Add this to  `app/public/manifest.json`:

```
{
  "name": "My Progressive Web App",
  "short_name": "My PWA",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "background_color": "#fff",
  "theme_color": "#3367D6",
  "description": "This is a sample description. Change it.",
  "lang": "en",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-256x256.png",
      "sizes": "256x256",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

[Docs to customize manifest.json](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json){:target="blank"}

## Part 2. Add a ServiceWorker

* Console:

```
yarn add webpacker-pwa
mkdir app/javascript/service_workers
echo > app/javascript/service_workers/service-worker.js
```

* Update `config/webpack/environment.js` to look like this:

```
const { resolve } = require('path');
const { config, environment, Environment } = require('@rails/webpacker');
const WebpackerPwa = require('webpacker-pwa');
new WebpackerPwa(config, environment);
module.exports = environment;
```

(does not include bootstrap (jquery & popper) settings)

* Add this to `javascript/packs/application.js`:

```
window.addEventListener('load', () => {
  navigator.serviceWorker.register('/service-worker.js').then(registration => {
    console.log('ServiceWorker registered: ', registration);

    var serviceWorker;
    if (registration.installing) {
      serviceWorker = registration.installing;
      console.log('Service worker installing.');
    } else if (registration.waiting) {
      serviceWorker = registration.waiting;
      console.log('Service worker installed & waiting.');
    } else if (registration.active) {
      serviceWorker = registration.active;
      console.log('Service worker active.');
    }
  }).catch(registrationError => {
    console.log('Service worker registration failed: ', registrationError);
  });
});
```

* Add this to `webpacker.yml`:

```
default:
  service_workers_entry_path: service_workers
```

* Inside `app/javascript/service_workers/service-worker.js` add:

```
self.addEventListener('install', function(event) {
    console.log('Service Worker installing.');
});

self.addEventListener('activate', function(event) {
    console.log('Service Worker activated.');
});
self.addEventListener('fetch', function(event) {
    console.log('Service Worker fetching.');
});
```

* add `public/service-worker.js*` to ``.gitignore`

![add-to-gitignore](/assets/2021-01-11-ruby-on-rails-6-make-a-progressive-web-app-pwa/add-to-gitignore.png)

```
echo 'public/service-worker.js*' >> .gitignore
```

* run `bin/webpack` to see if it is working

****

* Based on [this article](https://dev.to/coorasse/the-progressive-rails-app-46ma){:target="blank"}
* Yarn [webpacker-pwa](https://yarnpkg.com/package/webpacker-pwa){:target="blank"}
* [other article](https://medium.com/@benmiriello_36460/amadeus-api-part-3-fff3c12e46cc){:target="blank"}
* [custom-offline-page](https://googlechrome.github.io/samples/service-worker/custom-offline-page/){:target="blank"}
* [Add_to_home_screen](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Add_to_home_screen){:target="blank"}

If you are using bootstrap
```
const { resolve } = require('path');
const { config, environment, Environment } = require('@rails/webpacker');
const WebpackerPwa = require('webpacker-pwa');
new WebpackerPwa(config, environment);

const webpack = require("webpack")
environment.plugins.append("Provide", new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    'window.jQuery': 'jquery',
    Popper: ['popper.js', 'default']
  }))

module.exports = environment
```
