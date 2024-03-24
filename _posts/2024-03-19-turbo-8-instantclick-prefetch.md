---
layout: post
title: "Turbo 8 Prefetch (InstantClick)"
author: Yaroslav Shmarov
tags: turbo-rails prefetch instantclick
thumbnail: /assets/thumbnails/turbo.png
youtube_id: CxWPMnRoud0
---

Inspired by [instaclick.io](http://instantclick.io/), instaclick [has been added](https://github.com/hotwired/turbo/pull/1101) as a default behaviour in Turbo 8.

InstantClick makes an assumption about potential user behaviour: now whenever you **hover** on a link, it will fire a GET request to retrieve that page. So when you actually click on the link, it will load faster.

InstantClick/prefetch example:

![turbo-8-prefetch-intantclick](/assets/images/turbo-8-prefetch-intantclick.gif)

Such a request will also have a header `X-Sec-Purpose: prefetch`

Here are a few tips based on [the docs](https://github.com/hotwired/turbo/pull/1101/files#diff-9c52929162118b63d4b92d7cfdd942a11cbb266179248b2500d5cadc8c42bfd5)

These links will never be prefetched:

```ruby
# current page
link_to "Comments", request.path
# anchor tags (obviously on current page)
link_to "Comments", "#comments"
# non-GET requests
link_to "Upvote", upvote_post_path(@post), data: {turbo_method: :post}
# other websites
link_to "Other website", "https://superails.com"
```

Disable prefetch:

```ruby
link_to "Admin", admin_path, data: {turbo_prefetch: false}
link_to "Admin", admin_path, data: {turbo: false}

# disable for a block
<div data-turbo="false">
  link_to "Admin", admin_path
</div>

# disable globally in application.html.erb
<meta name="turbo-prefetch" content="true" />
```

Caution:
* wrong assumptions can lead to more server load
* you would not want to count these prefetch requests as page visits
* whenever you re-hover on a link, it will trigger yet another request (to always have updated content)

![turbo-8-instantclick-prefetch-weird-revisits](/assets/images/turbo-8-instantclick-prefetch-weird-revisits.gif)

Mentions:
- [instant-page-loads-with-turbolinks-and-prefetch](https://www.mskog.com/posts/instant-page-loads-with-turbolinks-and-prefetch)
- [twitter docusealco](https://twitter.com/docusealco/status/1747563403516723517)
- [twitter DHH 1](https://twitter.com/dhh/status/1754518694066266398)
- [twitter DHH 2](https://twitter.com/dhh/status/1755263774062526747)
- [twitter DHH 3](https://twitter.com/dhh/status/1755363667120734643)
