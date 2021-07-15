---
layout: post
title: "Role scopes with gem Ransack"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails rolify
thumbnail: /assets/thumbnails/ransack.png
---

The magic of Rolify is not in just **assigning user roles**, but in assigning user roles to resources. 

Meaning, 2 different posts can easily have different **admins** and **moderators**.

But Ransack has no default scopes to see all user with a role for a post, or all posts that a user has a role for.

Here are some example relationship scopes that you can add to your models and fix the "problem":

### Scoping

user.rb
```ruby
has_many :posts, through: :roles, source: :resource, source_type: :Post
has_many :moderated_posts, -> { where(roles: {name: :moderator}) }, through: :roles, source: :resource, source_type: :Post
```
let's you do
```ruby
@user.posts 
# => [ all the posts where the @user has a role ]
@user.moderated_posts
# => [ all the posts where the @user has a moderator ]
```
post.rb
```ruby
has_many :users, through: :roles, class_name: 'User', source: :users
has_many :moderators, -> { where(:roles => {name: :moderator}) }, through: :roles, class_name: 'User', source: :users
```
let's you do
```ruby
@post.users
# => [ all the users that have a role in this post ]
@post.moderators
# => [ all the users that have a moderator role in this post ]
```
