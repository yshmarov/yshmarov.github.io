source "https://rubygems.org"
gem "jekyll", "~> 4.4"
gem "minima", git: "https://github.com/jekyll/minima"
group :jekyll_plugins do
  gem "jekyll-feed"
  gem 'jekyll-sitemap'
  gem 'jekyll-seo-tag'
  gem 'jekyll-pwa-plugin', "~> 2.2" # 5.1.5 crashes on sites with posts (lavas-project/jekyll-pwa#39); https://github.com/lavas-project/jekyll-pwa
  gem 'jekyll-tagging'
  gem 'jekyll-tagging-related_posts'
  gem 'jekyll-target-blank'
  gem 'jekyll-postfiles'
  gem 'jekyll-og-image'
end

group :test do
  gem 'rake'
  gem 'nokogiri'
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :windows, :jruby do
  gem "tzinfo", ">= 1.2"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", platforms: :windows

gem "webrick", "~> 1.9"
