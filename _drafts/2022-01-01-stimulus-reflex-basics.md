Stimulus Reflex


bundle add redis cable_ready stimulus_reflex

yarn add cable_ready stimulus_reflex
bundle exec rails stimulus_reflex:install
bundle exec rails g scaffold Post username body likes_count:integer reposts_count:integer --no-jbuilder

null false default 0

bundle exec rails db:migrate