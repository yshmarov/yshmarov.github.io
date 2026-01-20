---
layout: post
title: "My recommended Jekyll plugins in 2025"
author: Yaroslav Shmarov
categories: jekyll theming
tags: ruby rails
thumbnail: /assets/thumbnails/cog.png
---

### Extend [Minima](https://github.com/jekyll/minima) theme

```yml
# _config.yml
minima:
  # skin: classic
  skin: solarized-dark
  social_links:
    - { platform: github, user_url: "https://github.com/jekyll/jekyll" }
    - { platform: twitter, user_url: "https://twitter.com/jekyllrb" }
author:
  name: John Smith
  email: "john.smith@foobar.com"
show_excerpts: true
```

### Add a custom page

Copypaste `about.md` and rename the new file to `newsletter.md`, inside too.

Add links to navbar:

```yml
# _config.yml
header_pages:
  - about.md
  - newsletter.md
```

I advise you to also rename `.markdown` files to `.md`.

### Open external links in new tab

Use [gem Jekyll target blank](https://github.com/keithmifsud/jekyll-target-blank)

### [gem Jekyll SEO tag](https://github.com/jekyll/jekyll-seo-tag)

No action required! Minima theme has SEO tags installed by default.

### [gem Jekyll Opengraph image](https://github.com/igor-alexandrov/jekyll-og-image)

Add image previews to social sharing.

```yml
# _config.yml

# add these plugins
plugins:
  - jekyll-seo-tag
  - jekyll-og-image

# customise og_image
og_image:
  output_dir: "assets/images/og"
  image: "/assets/images/igor.jpeg"
  domain: "igor.works"
  border_bottom:
    width: 20
    fill:
      - "#820C02"
      - "#A91401"
      - "#D51F06"
      - "#DE3F24"
      - "#EDA895"
```

Add libvips to CI:

```yml
# .github/workflows/jekyll.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      # ADD THIS ->
      - name: Install libvips
        env:
          DEBIAN_FRONTEND: noninteractive
        run: sudo apt-get install --fix-missing libvips
```

### [gem Jekyll Sitemap](https://github.com/jekyll/jekyll-sitemap)

Important for search engines.

Install the gem and you can visit [http://localhost:4000/sitemap.xml](http://localhost:4000/sitemap.xml)

```yml
# _config.yml
url: "https://example.com"
plugins:
  - jekyll-sitemap
```

### [gem Jekyll RedirecFrom](https://github.com/jekyll/jekyll-redirect-from)

Redirect (old) URLs to the current post.

```diff
# _posts/2024-12-24-jekyll-plugins.md
---
layout: post
title: "Recommended Jekyll plugins"
categories: jekyll theming
+redirect_from:
+  - /old-link
+  - /other
---
```

Now `http://localhost:4000/old-link` will redirect to `http://localhost:4000/jekyll-plugins`.

And `http://localhost:4000/other` will redirect to `http://localhost:4000/jekyll-plugins`.

### Link to edit page on Github

In `github_edit_url` input your repo url

```yml
# _config.yml
github_edit_url: "https://github.com/yshmarov/yshmarov.github.io/blob/master/"
```

```html
<!-- _layouts/post.html -->
<a href="{{ site.github_edit_url }}{{ page.path }}" target="_blank">Edit this page</a>
```

### Discovery feature: Tag pages

Use gem [Jekyll Tagging](https://github.com/pattex/jekyll-tagging)

On a post page, display links to tags.

```diff
# _posts/2024-12-24-jekyll-plugins.md
---
layout: post
title: "Recommended Jekyll plugins"
+tags: ruby rails
---
```

Be sure to set layout to `base`

```diff
# _layouts/tag_page.html
---
-layout: default
+layout: base
---
```

Display tags for each post in the post page:

```html
<!-- _layouts/post.html -->
{%- if page.tags -%} Tags: {%- for tag in page.tags -%}
<a href="{{ site.baseurl }}/tag/{{ tag | slugify }}">{{ tag }}</a>
{%- if forloop.last == false %}, {% endif -%} {%- endfor -%} {%- endif -%}
```

[Here's how](https://github.com/yshmarov/yshmarov.github.io/commit/c8b19cc0861bb451a390845f8eb7da1b8b28f1a1#diff-e73b35364c60ba845bb11a95b54e7b8e0439b5aafc61723021cd0ea7b56a709cR41) I implemented it in another app.

### Discovery feature: List of similar posts

Use [gem jekyll-tagging-related_posts](https://github.com/toshimaru/jekyll-tagging-related_posts)

On a post page, display list of similar posts (based on amount of matching tags).

### Add anchor tags to headings

[Copy this](https://github.com/yshmarov/yshmarov.github.io/pull/3)

### Other plugins & features to consider:

- Link to prev, next post
- [jekyll-postfiles](https://github.com/nhoizey/jekyll-postfiles) - scope files to folders
- [jekyll-import](https://github.com/jekyll/jekyll-import) - import blog from other platform
- [github-metadata](https://github.com/jekyll/github-metadata) - looks useful, but no idea why
- [jekyll-admin](https://github.com/jekyll/jekyll-admin) - does not work for me
- [jekyll-gist](https://github.com/jekyll/jekyll-gist) - embed gists

That's it!
