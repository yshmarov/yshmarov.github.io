---
layout: post
title: "Stripe Part 1. Legacy Stripe Payments guide"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails stripe
thumbnail: /assets/thumbnails/telegram.png
---

This post does not cover creating a Stripe account and obtaining an API key.

This is not the most up-to-date Stripe payments method, but it works.

### TODO: Button for a person to pay specific ammount for a product.

gemfile:
```
gem "stripe" 
```
config/initializers/stripe.rb
```
Stripe.api_key = Rails.application.credentials[Rails.env.to_sym][:stripe][:secret]
```
any view:
```
<%= form_tag charge_path, method: :post do %>
  <script class="stripe-button" 
    data-amount="<%= @plan.amount %>" 
    data-description="<%= current_tenant.name %>" 
    data-email="<%= current_user.email %>" 
    data-key="<%= Rails.application.credentials[Rails.env.to_sym][:stripe][:publishable] %>" 
    data-locale="auto" 
    src="https://checkout.stripe.com/checkout.js">
  </script>
<% end %>
```
app/controllers/charges_controller.rb
```
  def charge
    subscription = current_tenant.subscription
    plan = subscription.plan

    if plan.amount > 0
      customer = Stripe::Customer.create(
        email: params[:stripeEmail],
        source: params[:stripeToken]
      )
      charge_stripe = Stripe::Charge.create(
        customer: customer.id,
        amount: plan.amount,
        description: current_tenant.name,
        currency: plan.currency
      )
    end

    charge = Charge.create(
      subscription: subscription,
      period_start: subscription.ends_at,
      period_end: subscription.ends_at + subscription.plan.interval_period,
      plan_name: plan.name,
      plan_amount: plan.amount,
      plan_currency: plan.currency,
      plan_interval: plan.interval,
      plan_conditions: plan.max_members
    )

    if charge.save
      subscription.update(ends_at: subscription.ends_at + subscription.plan.interval_period)
      redirect_to tenant_path(current_tenant), notice: "Charged successfully. Subscription updated."
    else
      redirect_to tenant_path(current_tenant), alert: "Something went wrong. Please try again."
    end
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to tenant_path(current_tenant), alert: "Payment went wrong. Please try again."
  end
```
