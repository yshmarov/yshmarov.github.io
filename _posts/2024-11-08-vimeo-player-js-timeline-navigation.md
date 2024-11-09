---
layout: post
title: Custom chapters with Vimeo Player API
author: Yaroslav Shmarov
tags: ruby rails youtube api vimeo stimulus
thumbnail: /assets/thumbnails/youtube.png
---

I've just implemented Video timestamp navigation on videos embeded on [SupeRails](https://superails.com/posts):

![superails chapter navigation inside video](/assets/images/superails-video-chapters.gif)

I was inspired by Chapters on Youtube:

![youtube video chapters](/assets/images/youtube-chapters.png)

In my app I embed videos with Vimeo.

To navigate to a timestamp in the vimeo player, you need to use the [https://github.com/vimeo/player.js](https://github.com/vimeo/player.js) API.

First, install the package [https://github.com/vimeo/player.js](https://github.com/vimeo/player.js)

```shell
./bin/importmap pin @vimeo/player
rails g stimulus vimeo
```

Stimulus controller to click `play`, or **navigate** to a timestamp:

```js
// app/javascript/controllers/vimeo_controller.js
import { Controller } from "@hotwired/stimulus"
import Player from '@vimeo/player';

// Connects to data-controller="vimeo"
export default class extends Controller {
  static targets = ["player"]

  connect() {
    // continue only if the embedded video is from Vimeo
    try {
      this.player = new Player(this.playerTarget);
    } catch {}
  }

  play(event) {
    event.preventDefault()
    this.player.play()
  }

  setCurrentTime(event) {
    event.preventDefault()
    this.player.setCurrentTime(event.target.dataset.time)
  }
}
```

Embed a vimeo player, and add play and chapter navigation buttons:

```html
<div data-controller="vimeo">
  <iframe src="https://player.vimeo.com/video/1023706220?h=7e9bb172b6"
          frameborder="0"
          data-vimeo-target="player"
          allowfullscreen>

  <button data-action="click->vimeo#play">play</button>
  <button data-action="vimeo#setCurrentTime" data-time="40">40</button>
  <button data-action="vimeo#setCurrentTime" data-time="90">90</button>
</div>
```

### Parse timestamps from text

To add timestamps/chapters on Youtube, you simply edit a video description and type in the timestamps.

Next, Youtube parses your video description and extracts the timestamp `time` and `description` values.

We can parse a video description with Regex:

```ruby
# app/helpers/application_helper.rb
  def timestamps_array_from_text(text)
    text.scan(/(\d+:\d+)\s(.+)/).map do |match|
      time = match[0].split(':').map(&:to_i)
      seconds = (time[0] * 60) + time[1]
      { human_time: match[0], time: seconds, text: match[1] }
    end
  end
```

Test the parser:

```ruby
  test 'timestamps_array_from_text' do
    text = "hello world 0:00 Introduction\n0:10 First section\n2:30 Second section"
    expected = [
      { human_time: '0:00', time: 0, text: 'Introduction' },
      { human_time: '0:10', time: 10, text: 'First section' },
      { human_time: '2:30', time: 150, text: 'Second section' }
    ]

    assert_equal expected, timestamps_array_from_text(text)
  end
```

Finally, display styled, clickable timestamps anywhere on your page (but within `data-controller="vimeo"`): 

```html
<ul>
  <% timestamps_array_from_text(text).each do |timestamp| %>
    <li>
      <button title="<%= timestamp[:text] %>" style="color: blue" data-action="vimeo#setCurrentTime" data-time="<%= timestamp[:time] %>"><%= timestamp[:human_time] %></button>
      <%= timestamp[:text] %>
    </li>
  <% end %>
</ul>
```

That's it! Custom chapter navigation works!
