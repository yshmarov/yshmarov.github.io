---
layout: post
title: "gem acts_as_votable 4: cached votes, vote scopes, Hotwire"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails acts_as_votable hotwire turbo
thumbnail: /assets/thumbnails/like.png
---

My previous [ActsAsVotable](https://github.com/ryanto/acts_as_votable){:target="blank"} posts:
1. [gem acts_as_votable 1: Like and Dislike posts with Vanilla JS]({% post_url 2021-05-03-gem-acts-as-votable %}){:target="blank"}
2. [gem acts_as_votable 2: reddit-style up and down voting]({% post_url 2021-05-10-gem-acts-as-votable-2 %}){:target="blank"}
3. [gem acts_as_votable 3: vote search scopes]({% post_url 2021-07-17-gem-acts-as-votable-3-useful-scopes %}){:target="blank"}

**This** is my current-best approach to reddit-style voting with Hotwire.

**Prerequisites**:
* rails 7 with Hotwire
* `gem devise` for `Users` model. Here's how you can make [Devise work with Rails 7]({% post_url 2021-11-12-turbo-devise %}){:target="blank"}

### 1. Install acts_as_votable. Models. Vote scopes.

```ruby
# console
rails g scaffold message body:text
bundle add acts_as_votable
rails generate acts_as_votable:migration
rails db:migrate
```

```ruby
# app/models/user.rb
  acts_as_voter
```

I strongly recommend to use vote_scopes. This way you can always easily add multiple vote types on a same model, like `like`, `bookmark`, `star`.

```ruby
# app/models/message.rb
  acts_as_votable

  # upvote or remove vote
  def upvote!(user)
    if user.voted_up_on? self, vote_scope: 'like'
      unvote_by user, vote_scope: 'like'
    else
      upvote_by user, vote_scope: 'like'
    end
  end

  # downvote or remove vote
  def downvote!(user)
    if user.voted_down_on? self, vote_scope: 'like'
      unvote_by user, vote_scope: 'like'
    else
      downvote_by user, vote_scope: 'like'
    end
  end
```

Now you can `like`/`unlike`/`dislike` via the console:

```ruby
user = User.first
message = Message.create(body: SecureRandom.hex)
message.upvote!(user) # like
message.upvote!(user) # if a vote exists => unlike
user.voted_for? message, vote_scope: "like" # true
message.get_upvotes(vote_scope: 'like').size # 1
message.get_downvotes(vote_scope: 'like').size # 0
message.find_votes_for(vote_scope: 'like').size # total votes count
ActsAsVotable::Vote.count # 1
```

Problem: I don't see a way to get `message.weighted_score` with a `vote_scope`.

### 2. Store [Cached votes](https://github.com/ryanto/acts_as_votable#caching) in the database

This is important for performance. Also to order posts by votes like `Post.order(cached_weighted_like_score: :desc)`

```ruby
# console
rails g migration AddCachedScopedLikeVotesToMessages
```
```ruby
class AddCachedScopedLikeVotesToMessages < ActiveRecord::Migration[7.0]
  def change
    change_table :messages do |t|
      t.integer :cached_scoped_like_votes_total, default: 0
      t.integer :cached_scoped_like_votes_score, default: 0
      t.integer :cached_scoped_like_votes_up, default: 0
      t.integer :cached_scoped_like_votes_down, default: 0
      t.integer :cached_weighted_like_score, default: 0
      t.integer :cached_weighted_like_total, default: 0
      t.float :cached_weighted_like_average, default: 0.0

      # calculate the existing votes
      # Message.find_each { |p| p.update_cached_votes("like") }
    end
  end
end
```

### 3. View, Controller

Let's allow the user to upvote/downvote on a message from the browser.

```ruby
# config/routes.rb
  resources :messages do
    member do
      patch :vote
    end
  end
```

So, the path to vote will be `vote_message_path(message)`.

Instead of having 2 methods `upvote` and `downvote`, we have just one method `vote`.

To distinguish whether we want to `upvote` or `downvote`, we will be sending an additional `param[:type]` with the button:

```ruby
vote_message_path(message, type: :upvote)
vote_message_path(message, type: :downvote)
```

The controller action will respond accordingly:

```ruby
# app/controllers/messages_controller.rb
  def vote
    # return unless %w[upvote downvote].include?(params[:type])
    @message = Message.find(params[:id])

    case params[:type]
    when 'upvote'
      @message.upvote! current_user
    when 'downvote'
      @message.downvote! current_user
    else
      # redirect_to request.url, alert: "no such vote type" and return
      return redirect_to request.url, alert: "no such vote type"
    end
    flash.now[:notice] = params[:type]
    respond_to do |format|
      format.html do
        redirect_to request.url
      end
      format.turbo_stream do
        render turbo_stream:
          turbo_stream.replace(@message,
                                partial: 'messages/message',
                                locals: { message: @message })
      end
    end
  end
```

Logic for the upvote/downvote button text:

```ruby
# app/helpers/application_helper.rb
  def upvote_label(message, user)
    vote_message = if user.voted_up_on? message, vote_scope: 'like'
                     'UN-vote'
                   else
                     'UP-vote'
                   end
    tag.span do
      "#{message.cached_scoped_like_votes_up} #{vote_message}"
    end
  end

  def downvote_label(message, user)
    vote_message = if user.voted_down_on? message, vote_scope: 'like'
                     'UN-vote'
                   else
                     'DOWN-vote'
                   end
    tag.span do
      "#{message.cached_scoped_like_votes_down} #{vote_message}"
    end
  end
```

Let's display:
* buttons to upvote/downvote
* total votes `(upvotes + downvotes)`
* rating `(upvotes - downvotes)`

```ruby
# app/views/messages/_message.html.erb
<div id="<%= dom_id message %>">
  <%= simple_format(message.body) %>

  <%= button_to [:vote, message], params: { type: :upvote }, method: :patch do %>
    <%= upvote_label(message, current_user) %>
  <% end %>

  Total votes:
  <%= message.cached_scoped_like_votes_total %>
  Rating:
  <%= message.cached_weighted_like_score %>

  <%= button_to [:vote, message], params: { type: :downvote }, method: :patch do %>
    <%= downvote_label(message, current_user) %>
  <% end %>
</div>
```

Cool stuff! You can respond with either `html` (full page redirect), or `turbo_stream` (ajax):

```ruby
<%= button_to upvote_label(message, current_user), vote_message_path(message, type: :upvote, format: :html), method: :patch %>
<%= button_to upvote_label(message, current_user), vote_message_path(message, type: :upvote, format: :turbo_stream), method: :patch %>
```

### 4. Get all records that a user voted for

```ruby
# all voted entities
user.find_voted_items # voted
user.find_up_voted_items # upvoted
user.find_down_voted_items # downvoted

# all voted entities with a scope
user.find_voted_items(vote_scope: 'like')
user.find_up_voted_items(vote_scope: 'like')
user.find_down_voted_items(vote_scope: 'like')

# only voted Messages with a scope
user.find_votes_for_class(Message, vote_scope: "like")
user.find_up_votes_for_class(Message, vote_scope: "like")
user.find_down_votes_for_class(Message, vote_scope: "like")
```

That's it!
