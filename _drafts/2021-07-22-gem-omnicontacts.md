---
layout: post
title: "Let users import their google contacts into your app"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails omnicontacts google
thumbnail: /assets/thumbnails/google.png
---

google api
```
#https://console.cloud.google.com

#Authorized redirect URIs

https://6db7561ec85d48a09a2bf421acd194e4.vfs.cloud9.eu-central-1.amazonaws.com/contacts/gmail/contact_callback

#example output

[{:id=>"http://www.google.com/m8/feeds/contacts/elviramamedo%40gmail.com/base/607f26b88aa9197f", 
:first_name=>"Julia", 
:last_name=>nil, 
:name=>"Julia", 
:emails=>[], 
:gender=>nil, 
:birthday=>nil, 
:profile_picture=>nil, 
:relation=>nil, 
:addresses=>[], 
:phone_numbers=>[{:name=>"mobile", :number=>"+4881023488"}], 
:dates=>nil, 
:company=>nil, 
:position=>nil, 
:phone_number=>"+4881023488"}, 
{next record},
{next record}]
```

gemfile
```
gem "omnicontacts"
```

contact.rb
```ruby
class Contact < ApplicationRecord
  validates :import_id, presence: true
  validates :import_id, uniqueness: true
  #validates :import_id, uniqueness: true, scope: :user_id
end
```

contacts_controller.rb
```ruby
class ContactsController < ApplicationController
  def import
    #IMPORT CONTACTS FROM GOOGLE
    @contacts = request.env['omnicontacts.contacts']
    @user = request.env['omnicontacts.user']

    @contacts.each do |contact|
      new_contact = Contact.find_or_create_by(import_id: contact[:id])
      new_contact.email = contact[:email]
      new_contact.import_id = contact[:id]
      new_contact.name = contact[:name]
      new_contact.first_name = contact[:first_name]
      new_contact.last_name = contact[:last_name]
      new_contact.phone_number = contact[:phone_number]
      new_contact.save
    end
    redirect_to contacts_path, notice: 'Contacts successfully imported.'
  end

  def index
    @contacts = Contact.all
  end

  def failure
    redirect_to contacts_path, notice: 'Failure. Try again.'
  end
end
```

#contacts/index.html.haml
```ruby
= link_to "Import Google Contacts", "/contacts/gmail"
.table-responsive
  %table.table.table-bordered.table-striped.table-sm.table-hover
    %thead
      %tr
        %th email
        %th import_id
        %th name
        %th first_name
        %th last_name
        %th phone_number
    %tbody
      - @contacts.each do |contact|
        %tr
          %td= contact.email
          %td= contact.import_id
          %td= contact.name
          %td= contact.first_name
          %td= contact.last_name
          %td= contact.phone_number
```

#config/initializers/omnicontacts.rb

```
require "omnicontacts"

Rails.application.middleware.use OmniContacts::Builder do
  importer :gmail, 
    Rails.application.credentials.dig(:google_oauth2, :client_id).to_s,
    Rails.application.credentials.dig(:google_oauth2, :client_secret).to_s,
    {:redirect_path => "/contacts/gmail/contact_callback", 
        :max_results => 1500}
end
```

rails g migration create_contacts 
```ruby
class CreateContacts < ActiveRecord::Migration[6.0]
  def change
    create_table :contacts do |t|
      t.string :email
      t.string :import_id
      t.string :name
      t.string :first_name
      t.string :last_name
      t.string :phone_number

      t.timestamps
    end
  end
end
```

routes.rb
```ruby
  #contacts google import
  get "contacts", to: "contacts#index"
  get "/contacts/:provider/contact_callback", to: "contacts#import"
  get "/contacts/failure", to: "contacts#failure"
```