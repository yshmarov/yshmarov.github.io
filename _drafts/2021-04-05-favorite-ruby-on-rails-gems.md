# Gems I use in every app

## authentication
gem "devise" # user authentication
gem "devise_invitable"
gem "omniauth" # authorization via social media account

# development
gem "haml-rails" # better markup for views than .html.erb
gem "simple_form" # better way to create rails forms
gem "faker" # populate database with fake data via seeds.rb

# data manipulation
gem "pagy" # ultimate pagination gem
gem "ransack" # filter and sort data

# production
gem "exception_notification" # email notifications if any errors in production
gem "invisible_captcha" # 
gem "cocoon"
gem "public_activity" # see all activity in the app

# Gems I use often
gem "aws-sdk-s3", require: false # save images and files in production
gem "active_storage_validations" # validate image and file uploads

# authorization
gem "pundit" # authorization (different roles have different accesses)

# Gems I use conditionally
gem "acts_as_tenant"
gem "omnicontacts" 
gem "rails-i18n"
gem "devise-i18n"


gem "ice_cube"
gem "simple_calendar"
gem "money-rails"
gem "rails-erd", group: :development # sudo apt-get install graphviz; bundle exec erd
gem "ranked-model" # give serial/index numbers to items in a list
gem "wicked_pdf" # PDF for Ruby on Rails
gem "wicked" # multistep forms
gem "sitemap_generator" # SEO and webmasters

gem "chartkick" # charts #yarn add chartkick chart.js
gem "groupdate" # group records by day/week/year
gem "stripe"

### Gems I stopped using

* `gem "friendly_id"` - pretty URLs that hide record ID. UUID instead
* `gem "font-awesome-sass"` - fontawesome icons. yarn package instead
* `gem "bootstrap"` - bootstrap css. yarn package instead
* `gem "rolify"` - custom lightweight solution
* `gem "acts_as_taggable"` - custom lightweight solution
* `gem "recaptcha"` - replaced with gem invisible_captcha
* `gem "milia"` - replaced with gem acts_as_tenant

# Gems I want to start using
pg_search

gem "httparty", "~> 0.18" # send messages to telegram


6. gem discard - soft delete data
24. gem schedulable/ice_cube/recurring_select…
25. gem standard - code 
28. gem acts_as_tenant
29. gem acts_as_votable
30. gem acts_as_taggable
31. gem meta-tags
	a. https://railsbytes.com/public/templates/XnJs6n
33. gem schedulable

# Gems I don"t want to start using

32. gem draper
34. gem config

35. gem raty
36. gem merit
37. gem validates_overlap
38. gem validates_timeliness
