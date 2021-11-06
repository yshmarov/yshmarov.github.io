---
layout: post
title: "Pretty URLs with gem friendly_id"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails friendly_id
thumbnail: /assets/thumbnails/url.png
---

![friendly id url example](/assets/images/friendly_id_urls.png)

* [Gem Friendly_id](https://github.com/norman/friendly_id){:target="blank"}
* [Example implementation - Superails](https://github.com/corsego/52-friendly-id/commit/00989cb4dc0a14409e067220707e24498208bd4e){:target="blank"}

### 1. Minimal setup - no additional column

```sh
bundle add friendly_id
# will install the gem
```

```ruby
#app/models/inbox.rb
  extend FriendlyId
  friendly_id :name
```

```diff
#app/controllers/inboxes_controller.rb
  def set_inbox
--    @inbox = Inbox.find(params[:id])
++    @inbox = Inbox.friendly.find(params[:id])
  end
```

### 2. `:finders` - always add it!

```diff
#app/models/inbox.rb
  extend FriendlyId
--  friendly_id :name
++  friendly_id :name, use: [:finders]
```

```diff
#app/controllers/inboxes_controller.rb
  def set_inbox
++    @inbox = Inbox.find(params[:id])
--    @inbox = Inbox.friendly.find(params[:id])
  end
```

### 2. `:slugged` - always add it too!

```sh
rails g migration AddSlugToInboxes slug:uniq
# will add column that will store the friendly_id
```

```diff
#app/models/inbox.rb
  extend FriendlyId
--  friendly_id :name, use: [:finders]
++  friendly_id :name, use: [:finders, :slugged]
```

```sh
Inbox.find_each(&:save)
# update the slug for all existing records
# in the above case, slug = name
```

* 2.1. you can create non-attribute slug names, like randoms

```diff
#app/models/inbox.rb
  extend FriendlyId
--  friendly_id :name, use: [:finders, :slugged]
++  friendly_id :random_hex, use: [:finders, :slugged]
++  def random_hex
++    SecureRandom.hex
++  end
```

* 2.2. candidates - use longer option if shorer one is taken

```diff
#app/models/inbox.rb
  extend FriendlyId
--  friendly_id :name, use: [:finders, :slugged]
++  friendly_id :slug_candidates, use: [:finders, :slugged]
++   def slug_candidates
++     [
++       :name,
++       [:name, :description],
++       [:name, :descroption, :created_at]
++     ]
++   end
```

### 4. Conditionally auto-update slug

```diff
#app/models/inbox.rb
  extend FriendlyId
  friendly_id :name
++  def should_generate_new_friendly_id?
++    name_changed?
++  end
```

* [Dirty - check if attrubite changed](https://api.rubyonrails.org/classes/ActiveModel/Dirty.html){:target="blank"}
* [Good post about `*_changed`](https://blog.saeloun.com/2020/03/24/rails-attribute_name_previously_changed-accepts-from-and-to-arguments.html){:target="blank"}

NOTE: this can be a bit buggy:
* go to `edit`
* change `name` to something invalid
* submit, get normal validation error
* change `name` to something valid
* submit, get `ActiveRecord::RecordNotFound (can't find record with friendly id: "ger"):`

### 5. `:history`. Customizing `friendly_id.rb`

All the new slugs will be saved in a separate database table -> you will be able to access records via their **OLD URLs**!

```diff
#app/models/inbox.rb
  extend FriendlyId
--  friendly_id :name, use: [:finders, :slugged]
++  friendly_id :name, use: [:finders, :slugged, :history]
```

```sh
rails generate friendly_id
# create db/migrate/20211105220542_create_friendly_id_slugs.rb
# create config/initializers/friendly_id.rb
```
