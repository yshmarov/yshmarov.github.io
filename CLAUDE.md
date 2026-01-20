# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Jekyll-based blog (SupeRails Blog) focused on Ruby on Rails development tips and tutorials. It uses the Minima theme with customizations and is deployed to GitHub Pages at blog.superails.com.

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
GitHub Actions workflow (`.github/workflows/jekyll.yml`) automatically builds and deploys to GitHub Pages on push to `master` branch. Uses Ruby 3.3.3.

### Comments
Uses Giscus (GitHub Discussions-based) for post comments.
