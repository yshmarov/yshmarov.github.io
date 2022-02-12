---
layout: post
title: 'Ruby on Rails: Serialization: saving address as a Hash'
author: Yaroslav Shmarov
tags: 
thumbnail: https://1.bp.blogspot.com/-TvCUh6z5qVk/X5xugnUVOJI/AAAAAAACFKk/ZPe3-lNHn3MPwEEE7ZNHOk6Jw_HLHMpiQCLcBGAsYHQ/s72-c/serialize%2Baddress%2Blogo.png
---

Often when creating an application you have to add an address field. 

But an address usually contains a Country, State, City, Zip, Street, Apt#.... 

How do you store all that info?🤔

one database column, just type inline (405 Howard Street, San Francisco, CA, USA 94105)
4 or 5 different database columns (Country: USA, State: CA, City: ....)
one database column, hash ({:country => USA, :state => CA, :city ....)
Personally I like the third option, because we don't have to create a lot of columns that are serving one small purpose - to store an address.

But how do we do it correctly? => SERIALIZERS😎

Example
#migration
class CreateClients < ActiveRecord::Migration[5.2]
  def change
    create_table :clients do |t|
      t.string :name
      t.text :address

      t.timestamps
    end
  end
end
notice that I'm storing address as text so that it can contain a lot of info!
  #client.rb

  serialize :address
  def address_line #for it to look pretty in the views
    if address.present?
      [address[:country], address[:city], address[:street], address[:zip]].join(', ')
    end
  end
And to be able to update the params, you need to add:

#clients_controller.rb
    def client_params
      params.require(:client).permit(:name, address: [:country, :city, :street, :zip])
    end
This way you will be permitted to update address[:country], address[:city], address[:street], address[:zip].

And the form:
#clients/form.html.haml
= f.fields_for :address, OpenStruct.new(f.object.address || {}) do |a|
    = f.label :country
    = a.text_field :country, id: :country
    = f.label :city
    = a.text_field :city, id: :city
    = f.label :street
    = a.text_field :street, id: :street
    = f.label :zip
    = a.text_field :zip, id: :zip
This way you can edit the value for each key that you want! 

Finally, the view:

  = @client.address_line


Read more here - Active Model Serialization - official docs🤓
https://api.rubyonrails.org/classes/ActiveModel/Serialization.html