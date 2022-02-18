---
layout: post
title: "#3 Turbo: Keep the audio playing after changing the page"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo audio mp3 turbo-drive
thumbnail: /assets/thumbnails/turbo.png
---

Task: when you switch the page the audio should be still playing like here [https://www.rework.fm/](https://www.rework.fm/)

![turbo-steam-music](/assets/images/turbo-steam-music.gif)

* obviously you should store the audio partial in a layout file that is shared across pages:

#app/views/layouts/application.html.erb
```ruby
  <body>
    <%= render 'shared/audio' %>
  </body>
```

* just wrap it into a `div` with an `id` and `data-turbo-permanent`

#app/views/shared/_audio.html.erb
```ruby
<div id="player1" data-turbo-permanent>
  <audio src="<%= audio_path 'song.mp3'%>" type="audio/mp3" controls>
  </audio>
</div>

<div id="player2" data-turbo-permanent="">
  <audio controls="">
    <source src="https://media.transistor.fm/9283b16f.mp3" type="audio/mp3">
  </audio>
</div>
```

In this case `song.mp3` is sourced from `#app/assets/images/song.mp3`

Resources:
* [https://github.com/hotwired/turbo/issues/64](https://github.com/hotwired/turbo/issues/64)
* [https://github.com/hotwired/turbo/issues/221](https://github.com/hotwired/turbo/issues/221)
