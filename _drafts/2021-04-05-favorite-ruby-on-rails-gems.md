
# Gems I use in every app
gem "devise" # user authentication
gem "omniauth" # authorization via social media account
gem "haml-rails" # better markup for views than .html.erb
gem "simple_form" # better way to create rails forms
gem "faker" # populate database with fake data via seeds.rb
gem "pagy" # ultimate pagination gem
gem "ransack" # filter and sort data
gem "exception_notification" # email notifications if any errors in production
gem "invisible_captcha" # 

# Gems I use often
gem "devise_invitable"
gem "cocoon"
gem "public_activity" # see all activity in the app
gem "aws-sdk-s3", require: false # save images and files in production
gem "active_storage_validations" # validate image and file uploads
gem "pundit" # authorization (different roles have different accesses)

# Gems I use conditionally
gem "acts_as_tenant"
gem "omnicontacts" 
gem "rails-i18n"
gem "devise-i18n"
gem 'ice_cube'
gem "simple_calendar"
gem 'money-rails'
gem "rails-erd", group: :development # sudo apt-get install graphviz; bundle exec erd
gem "ranked-model" # give serial/index numbers to items in a list
gem "wicked_pdf" # PDF for Ruby on Rails
gem "wicked" # multistep forms
gem 'sitemap_generator' # SEO and webmasters

gem "chartkick" # charts #yarn add chartkick chart.js
gem "groupdate" # group records by day/week/year
gem "stripe"

# Gems I stopped using
gem "friendly_id", "~> 5.2.4" # nice URLs and hide IDs
acts_as_taggable
gem "rolify" # give users roles (admin, teacher, student)
# gem 'font-awesome-sass', '~> 5.12.0' #add icons for styling #installed via yarn withot gem
gem bootstrap
gem "recaptcha" # for new user registration

# Gems I want to start using
pg_search

gem "httparty", "~> 0.18" # send messages to telegram