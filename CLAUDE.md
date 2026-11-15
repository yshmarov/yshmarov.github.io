# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is Yaroslav Shmarov's personal site and blog, built with Jekyll: a homepage about his work, plus /talks/, /teaching/, /about/ and the blog at /blog/. Homepage, talks and teaching content lives in `_data/profile.yml`. It uses the Minima theme with customizations and is deployed to GitHub Pages at blog.superails.com.

## Common Commands

```bash
# Serve locally (development)
bundle exec jekyll serve --port=8080

# Serve with drafts, future posts, and debugging
bundle exec jekyll serve --port=8080 --incremental --trace --future --drafts

# Build for production
bundle exec jekyll build

# Check for build errors
jekyll build --trace

# Install dependencies
bundle install
```

## Architecture

### Content Structure
- `_posts/` - Published blog posts (markdown files with `YYYY-MM-DD-title.md` naming)
- `_drafts/` - Unpublished draft posts
- `_layouts/` - Custom page layouts (extends Minima theme)
- `_includes/` - Reusable HTML partials
- `_plugins/` - Custom Jekyll plugins (currently just jekyll-tagging loader)
- `assets/` - Images, CSS, JS files

### Post Frontmatter
Posts use this frontmatter structure:
```yaml
---
layout: post
title: "Post Title"
author: Yaroslav Shmarov
tags: rails hotwire  # space-separated tags
thumbnail: /assets/thumbnails/rails-logo.png  # optional
youtube_id: VIDEO_ID  # optional, embeds YouTube video
categories: category1 category2  # optional
---
```

### Key Plugins
- `jekyll-og-image` - Auto-generates OpenGraph images for social sharing
- `jekyll-tagging` / `jekyll-tagging-related_posts` - Tag pages and related posts
- `jekyll-target-blank` - Opens external links in new tabs
- `jekyll-postfiles` - Allows post-specific assets in post directories
- `jekyll-pwa-plugin` - Progressive Web App support

### Deployment
GitHub Actions workflow (`.github/workflows/jekyll.yml`) automatically builds and deploys to GitHub Pages on push to `master` branch. Uses Ruby 4.0.9.

### Comments
Uses Giscus (GitHub Discussions-based) for post comments.

### Whop referral links

Use `https://whop.com/start/?code=CAKARK` for reader-facing Whop signup links in posts and profile content. This is Yaroslav's production Whop Partners referral link. Add a nearby disclosure that he may earn a commission and use `rel="sponsored nofollow"` on HTML links. Preserve sandbox, API, OAuth, callback, technical documentation and repository URLs. Do not add referral parameters to executable examples or login buttons.
