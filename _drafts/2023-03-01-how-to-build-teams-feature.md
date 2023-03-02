---
layout: post
title: "Teams and multitenancy without a gem"
author: Yaroslav Shmarov
tags: database architecture
thumbnail: /assets/thumbnails/polymorphism-sign.png
---

Think of Slack or Trello

Multitenancy - scoping different data models to an organization. Thing of trello b

https://twitter.com/robzolkos/status/1616807448865607681

_posts/2020-11-30-how-to-code-the-subscription-business-model-saas-service-as-a-service-part-1.md

```ruby
# app/models/user.rb
  # USER AUTHENTICATION
  has_many :members
  has_many :tenants, through: :members
```

```ruby
# app/models/member.rb
  # STORE ROLES HERE
  belongs_to :user
  acts_as_tenant :tenant, counter_cache: true
  validates :tenant_id, presence: true
  validates_uniqueness_of :user_id, scope: :tenant_id
```

```ruby
# app/models/tenant.rb
  has_many :members, dependent: :destroy
  has_many :users, through: :members

  # PLAN AND SUBSCRIPTION GOES HERE
  has_one :subscription, dependent: :destroy
  has_many :charges, dependent: :restrict_with_error
  has_one :plan, through: :subscription
```

```ruby
# app/controllers/members_controller.rb
class ProjectsController < ApplicationController
  include AuthorizeMember

  def invite
    email = params[:email]
    return redirect_to tenant_path(current_tenant), alert: 'No email proided' if email.blank?

    user = User.find_by(email:) || User.invite!({ email: }, current_user)
    return redirect_to tenant_path(current_tenant), alert: 'Email invalid' unless user.valid?

    user.members.find_or_create_by(tenant: current_tenant)
    redirect_to tenant_path(current_tenant), notice: 'Invitation sent!'
  end
end
```

```ruby
Rails.application.routes.draw do

  resources :tenants, param: :tenant_id do
    resources :members do
      collection do
        post :invite
      end
    end
  end
  devise_for :users
  root "home#index"
end
```

```ruby
<%= form_with url: invite_tenant_members_path(@tenant) do |form| %>
  <%= form.text_field :email %>
  <%= form.hidden_field :tenant_id, value: @tenant.id %>
  <%= form.submit 'invite' %>
<% end %>
```

```ruby
# app/controllers/authorized_controller.rb
class AuthorizedController < ApplicationController
  before_action :set_tenant
  before_action :authorize_member

  private

  def authorize_member
    return redirect_to root_path, alert: 'not authorized' unless @current_tenant.users.include? current_user
  end

  def set_tenant
    @current_tenant ||= Tenant.find(params[:tenant_id])
  end
end```

###

```ruby
# app/models/subscription.rb
```

```ruby
# app/models/charge.rb
```
```ruby
# app/models/plan.rb
```


- Multitenancy
- Teams
- Plans
- Subscriptions