---
layout: post
title: "Polymorphism 101. Part 2 of 3. Polymorphic Payments inside-out."
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails polymorphism polymorphic-associations
thumbnail: /assets/thumbnails/polymorphism-sign.png
---

In the previous example we had a pre-defined current record and want to create a comment for it.

In this example we will:
* select a polymorphic model 
* select a record to which we want to create a polymorphic child.

Example: `Clients` and `Teachers` can both create `Payments`.

To create a `payment` we:
* select a model for which we want to create a `payment` (`teacher` or `client`)
* select a `teacher` or `client` record

![polymorphic-payments.gif](/assets/images/polymorphic-payments.gif)

console
```
rails g scaffold payments amount:integer payable:references{polymorphic} --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
```
payment.rb
```
  belongs_to :payable, polymorphic: true
  validates :amount, presence: true

  def to_s
    [payable_type, payable_id, amount].join(" ")
  end
```
teacher.rb and client.rb
```
  has_many :payments, as: :payable, dependent: :restrict_with_error
```
payments/index.html.erb
```
<%= link_to "Client Payment", new_payment_path(payable_type: "Client") %>
<%= link_to "Teacher Payment", new_payment_path(payable_type: "Teacher") %>
```

By pressing one of the above links we will be redirected to an url like `/payments/new?payable_type=Client` or `/payments/new?payable_type=Teacher`.

Based on `?payable_type=Teacher` we give a collection of teachers to choose from:

payments/_form.html.erb
```
<%= simple_form_for(@payment) do |f| %>
  <%= f.input :payable_type, input_html: {value: @payment.payable_type || params[:payable_type]}, as: :hidden %>
  <% if @payment.payable_type.present? %>
    <%= f.input :payable_id, collection: @payment.payable_type.classify.constantize.all %>
  <% elsif params[:payable_type].present? %>
    <%= f.input :payable_id, collection: params[:payable_type].classify.constantize.all %>
  <% end %>
  <%= f.input :amount %>
  <%= f.button :submit %>
<% end %>
```

`@payment.payable_type.classify.constantize.all` gives us a collection of `@clients` or `@teachers` if we are **EDITING** a `payment`.

`params[:payable_type].classify.constantize.all` gives us a collection of `@clients` or `@teachers` if we are **CREATING** a `payment`.

This approach is good by not depending on any JS.

However it can be improved by being able to select the `payable_type` inside the form and than rendering the collection, rather than using `params`.
