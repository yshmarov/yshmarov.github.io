---
layout: post
title: "Gem Public Activity: Complete guide to total surveillance"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails public_activity surveillance
thumbnail: /assets/thumbnails/big-brother.png
---

A gem to track any activity in your application and record it to the database.

[Gem Source Code](https://github.com/chaps-io/public_activity)

Example:

![public activity list of activities](/assets/images/activity-list.png)

### basic setup

Gemfile

```ruby
gem 'public_activity'
```

console

```
rails g public_activity:migration
rake db:migrate
```

app/models/post.rb

```ruby
  include PublicActivity::Model
  tracked
```

### see if it works

console

```
PublicActivity::Activity.count
# => 0

p = Post.create(title: 'first post')

PublicActivity::Activity.count
# => 1

p.destroy!

PublicActivity::Activity.count
# => 2
```

### track current_user in activities

app/controllers/application_controller.rb

```
  include PublicActivity::StoreController 
```

app/models/post.rb

```ruby
  include PublicActivity::Model
  tracked owner: proc { |controller, model| controller.current_user }
  # tracked owner: Proc.new{ |controller, model| controller.current_user }
```

### track activities for the user model

app/models/user.rb
```ruby
  include PublicActivity::Model
  tracked owner: :itself
```


### track only particular activities

app/models/user.rb
```ruby
  include PublicActivity::Model
  tracked only: [:create, :destroy]
```

### enable / disable activities (for example in console or seeds.rb)

```
# Disable globally
PublicActivity.enabled = false

# Perform some operations that would normally be tracked by p_a:
Article.create(title: 'New article')

# Switch it back on
PublicActivity.enabled = true

# Disable p_a for Article class
Article.public_activity_off

# p_a will not do anything here:
@article = Article.create(title: 'New article')

# But will be enabled for other classes:
# (creation of the comment will be recorded if you are tracking the Comment class)
@article.comments.create(body: 'some comment!') 

# Enable it again for Article:
Article.public_activity_on
```

### get all activities for a particular object (a post)

controllers/posts_controller.rb
```ruby
  def show
    @post = Post.find(params[:id])
    @activities = PublicActivity::Activity
      .where(trackable_type: "Post", trackable_id: @post)
      .order(created_at: :desc)
  end
```

### activities as relationships, dependent destroy activities

app/models/post.rb

```ruby
  include PublicActivity::Model
  tracked owner: proc { |controller, model| controller.current_user }
  has_many :activities, as: :trackable, class_name: 'PublicActivity::Activity', dependent: :destroy
```

### save custom activity (example - in a controller action)

```ruby
  @post.create_activity :change_status, parameters: {status: @post.status}

  # or
  @post.create_activity action: 'poke', params: {reason: 'bored'}, recipient: @friend, owner: @user
```

### view to display all activities

any controller
```ruby
  def activity
    @activities = PublicActivity::Activity.order(created_at: :desc)
  end
```

###

activity.html.haml
```ruby
- @activities.each do |activity|
  = activity.created_at
  = time_ago_in_words(activity.created_at)
  = activity.trackable_type
  = link_to activity.trackable, activity.trackable
  = activity.key
  = link_to activity.owner, user_path(activity.owner) if activity.owner.present?
  = activity.parameters
```
