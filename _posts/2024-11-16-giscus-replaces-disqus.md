---
layout: post
title: Replace Disqus with Giscus comments
author: Yaroslav Shmarov
tags: jekyll
thumbnail: /assets/static-pages/yaro-avatar.png
---

I've been using Disqus comments on my blog for years. 

It's a good, easy to install tool. 

However I've always felt uneasy about sharing my data with an external tool that tracks everything.

I've always wanted to move to another comment system.

Now, when **Disqus is adding ads into my comment section**, it's the final straw for me. Time to leave.

![disqus will have ads](/assets/images/disqus-adds-ads.png)

I considered [utterances](https://github.com/utterance/utterances) that is based on **Github Issues**. Free? Yes. Dev friendly? Yes.

However [Gisqus](https://giscus.app) is based on **Github Discussions** - a new Github feature.

Github "Disgussions" `are superior to ` "Issues" for conversations.

So in [one tiny commit](https://github.com/yshmarov/yshmarov.github.io/commit/d0fcd2bae3608b0b1a0fcc8627c8dde6f327b6e7) I replaced Disqus with Giscus 🎉🎉

If Github was not an option, I would go with [mastodon-comments](https://github.com/dpecos/mastodon-comments)

I also saw [bartoszgorka's solution](https://bartoszgorka.com/github-discussion-comments-for-jekyll-blog) for adding Gisqus, but he does some changes in the `_config.yml` file for no useful reason. 

Just follow the guide on [Gisqus](https://giscus.app) and it will help you get all the right permissions and generate the script!
