---
layout: post
title: "#3 Turbo: Keep the audio playing after changing the page with data-turbo-permanent"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails hotwire turbo audio mp3 turbo-drive
thumbnail: /assets/thumbnails/turbo.png
youtube_id: uw8FHVjXnSE
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

```html
<!-- app/views/shared/_persistent.html.erb -->
<div id='hello' data-turbo-permanent="true">
  <%= audio_tag 'sample-audio-15s', controls: true %>
  <%= video_tag 'sample-video-5s', controls: true, width: '500px' %>
</div>

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

Another example of using `data-turbo-permanent` on [superails.com](https://superails.com) - search form and results are persisted across pages:

![persist-search-results-across-pages](/assets/images/data-turbo-permanent-persist-search-results.gif)

#### Bonus: Open video picture-in-picture when navigating to another page

```html
<script>
  function pictureOpen() {
    document.querySelector('video').requestPictureInPicture();
    // if you are a prick, you can hide the source so that the video is harder to dismiss!
    // document.getElementById('myvideo').style.display = 'none';
  }
</script>
<div>
  <%= link_to 'Home', root_path, onclick: 'pictureOpen()' %>
</div>

<div id='myvideo' data-turbo-permanent="true">
  <%= video_tag 'sample-video-5s', controls: true, width: '500px' %>
</div>
```

Resources:
* [Hotwire Turbo Docs: Persisting Elements Across Page Loads](https://turbo.hotwired.dev/handbook/building#persisting-elements-across-page-loads)
* [https://github.com/hotwired/turbo/issues/64](https://github.com/hotwired/turbo/issues/64)
* [https://github.com/hotwired/turbo/issues/221](https://github.com/hotwired/turbo/issues/221)
