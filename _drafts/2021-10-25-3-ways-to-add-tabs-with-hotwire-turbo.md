3-ways-to-add-tabs-with-hotwire-turbo.md

3 different ways to add tabbed content with Turbo in Ruby on Rails


0. Initial setup

rails g scaffold inbox name
rails g model message name inbox:references
rails g model comment name inbox:references
rails db:migrate

inbox.rb
  has_many :messages
  has_many :comments

rails c
Inbox.create name: SecureRandom.hex
Inbox.first.messages << Message.create name: SecureRandom.hex
Inbox.first.messages << Message.create name: SecureRandom.hex

1. 

    if turbo_frame_request?


