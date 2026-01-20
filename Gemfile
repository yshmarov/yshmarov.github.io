source "https://rubygems.org"
gem "jekyll"
gem "minima", git: "https://github.com/jekyll/minima"
group :jekyll_plugins do
  gem "jekyll-feed"
  gem 'jekyll-sitemap'
  gem 'jekyll-seo-tag'
  gem 'jekyll-pwa-plugin', "~> 2.2" # https://github.com/lavas-project/jekyll-pwa
  gem 'jekyll-tagging'
  gem 'jekyll-tagging-related_posts'
  gem 'jekyll-target-blank'
  gem 'jekyll-postfiles'
  gem 'jekyll-og-image'
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", "~> 1.2"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]

gem "webrick", "~> 1.9"