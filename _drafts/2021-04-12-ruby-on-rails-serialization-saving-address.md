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

<div class="separator" style="clear: both; text-align: center;"><a href="https://1.bp.blogspot.com/-TvCUh6z5qVk/X5xugnUVOJI/AAAAAAACFKk/ZPe3-lNHn3MPwEEE7ZNHOk6Jw_HLHMpiQCLcBGAsYHQ/s1191/serialize%2Baddress%2Blogo.png" imageanchor="1" style="margin-left: 1em; margin-right: 1em;"><img border="0" data-original-height="792" data-original-width="1191" src="https://1.bp.blogspot.com/-TvCUh6z5qVk/X5xugnUVOJI/AAAAAAACFKk/ZPe3-lNHn3MPwEEE7ZNHOk6Jw_HLHMpiQCLcBGAsYHQ/s320/serialize%2Baddress%2Blogo.png" width="320" /></a></div><p>Often when creating an application you have to add an <b>address field</b>.&nbsp;</p><p>But an address usually contains a Country, State, City, Zip, Street, Apt#....&nbsp;</p><p>How do you store all that info?🤔</p><p></p><ol style="text-align: left;"><li>one database column, just type inline (405 Howard Street, San Francisco, CA, USA 94105)</li><li>4 or 5 different database columns (Country: USA, State: CA, City: ....)</li><li>one database column, hash ({:country =&gt; USA, :state =&gt; CA, :city ....)</li></ol><p></p><p>Personally I like the <b>third option</b>, because we <b>don't have to create a lot of columns </b>that are serving one small purpose - to store an address.</p><p>But how do we do it correctly? =&gt; SERIALIZERS😎</p><h3 style="text-align: center;"><span style="white-space: pre-wrap;">Example</span></h3><div><pre style="overflow-wrap: break-word; white-space: pre-wrap;">#migration<br />class CreateClients &lt; ActiveRecord::Migration[5.2]<br />  def change<br />    create_table :clients do |t|<br />      t.string :name<br />      t.text :address<br /><br />      t.timestamps<br />    end<br />  end<br />end</pre></div><div><span style="white-space: pre-wrap;">notice that I'm storing <b>address </b>as <b>text </b>so that it can contain a lot of info!</span></div><p><span style="white-space: pre-wrap;">  #client.rb</span></p><pre style="overflow-wrap: break-word; white-space: pre-wrap;">  serialize :address<br />  def address_line #for it to look pretty in the views<br />    if address.present?<br />      [address[:country], address[:city], address[:street], address[:zip]].join(', ')<br />    end<br />  end</pre><p>And to be able to update the params, you need to add:</p><pre style="overflow-wrap: break-word; white-space: pre-wrap;">#clients_controller.rb<br />    def client_params<br />      params.require(:client).permit(:name, address: [:country, :city, :street, :zip])<br />    end</pre><p>This way you will be permitted to update&nbsp;<span style="white-space: pre-wrap;">address[:country], address[:city], address[:street], address[:zip].</span></p><div>And the form:</div><pre style="overflow-wrap: break-word; white-space: pre-wrap;">#clients/form.html.haml<br />= f.fields_for :address, OpenStruct.new(f.object.address || {}) do |a|<br />    = f.label :country<br />    = a.text_field :country, id: :country<br />    = f.label :city<br />    = a.text_field :city, id: :city<br />    = f.label :street<br />    = a.text_field :street, id: :street<br />    = f.label :zip<br />    = a.text_field :zip, id: :zip</pre><p>This way you can edit the value for each key that you want!&nbsp;</p><p>Finally, the view:</p><pre style="overflow-wrap: break-word; white-space: pre-wrap;">  = @client.address_line<br /></pre><div><p><br /></p><p>Read more here -&nbsp;<a href="https://api.rubyonrails.org/classes/ActiveModel/Serialization.html" target="_blank">Active Model Serialization - official docs</a>🤓</p></div>