https://www.sitepoint.com/start-your-seo-right-with-sitemaps-on-rails/
https://github.com/kjvarga/sitemap_generator

## Option 1:

* create a sitemap on a sitemap generator website. 
* Add it to `public/sitemap.xml`
* Direct `robots.txt` to the sitemap by adding in the line
```
Sitemap: https://www.corsego.com/sitemap.xml
```

## Option 2

Gemfile
```
gem 'sitemap_generator' # SEO and webmasters 
```

bad config/sitemap.rb
```
SitemapGenerator::Sitemap.default_host = "https://www.corsego.com"

SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do

  add new_user_registration_path, priority: 0.8, changefreq: "monthly"
  add new_user_session_path, priority: 0.8, changefreq: "monthly"
  add courses_path, priority: 0.7, changefreq: "daily"
  add tags_path, priority: 0.2, changefreq: "monthly"

  Course.where(published: true, approved: true).find_each do |course|
    add course_path(course), lastmod: course.updated_at
  end
end
```

better config/sitemap.rb

```
require 'aws-sdk-s3'
SitemapGenerator::Sitemap.compress = false
# Your website's host name
SitemapGenerator::Sitemap.default_host = "https://www.corsego.com"
# The remote host where your sitemaps will be hosted
SitemapGenerator::Sitemap.sitemaps_host = "https://corsego-public.s3.eu-central-1.amazonaws.com/"

SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  "corsego-public",
  aws_access_key_id: Rails.application.credentials.dig(:awss3, :access_key_id),
  aws_secret_access_key: Rails.application.credentials.dig(:awss3, :secret_access_key),
  aws_region: "eu-central-1"
)

SitemapGenerator::Sitemap.create do

  add new_user_registration_path, priority: 0.7, changefreq: 'monthly'
  add new_user_session_path, priority: 0.7, changefreq: 'monthly'
  add tags_path, priority: 0.3, changefreq: 'monthly'
  add courses_path, priority: 0.7, changefreq: 'daily'
  
  Course.where(approved: true, published: true).find_each do |course|
    add course_path(course), :lastmod => course.updated_at
  end
end
```

config/routes.rb
```
   get '/sitemap.xml', to: redirect("https://corsego-public.s3.eu-central-1.amazonaws.com/sitemap.xml")
```

public/robots.txt
```
# See https://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
# Sitemap: https://www.corsego.com/sitemap.xml
Sitemap: https://corsego-public.s3.eu-central-1.amazonaws.com/sitemap.xml

User-Agent: *
Disallow: /auth/facebook
Disallow: /auth/google_oauth2
Disallow: /courses/unapproved
Disallow: /courses/teaching
Disallow: /courses/new
Disallow: /courses/learning
Disallow: /courses/pending_review
Disallow: /users
Disallow: /activity
Disallow: /analytics
Disallow: /enrollments
Disallow: /enrollments/teaching

User-agent: *
Allow: /users/sign_in
Allow: /users/sign_up
Allow: /courses
Allow: /tags
```