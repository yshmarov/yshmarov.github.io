---
layout: post
title: "Polymorphism 101. Part 3 of 3. ActsAsTaggable without a gem. SelectizeJS"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails polymorphism polymorphic-associations tags selectize-js jquery
thumbnail: /assets/thumbnails/polymorphism-sign.png
---

[ActsAsTaggable](https://github.com/mbleigh/acts-as-taggable-on){:target="blank"} is a great gem, however you don't always need a swiss-army-knife heavy solution.
Let's build a lightweight solution on our own!

![polymorphic-tags.gif](/assets/images/polymorphic-tags.gif)

How does it work:
* A user can create multiple tags. 
* When you create a tag, you assign it to a category (`student`/`lesson`/`teacher`)
* A tag can be used only for it's category
* When creating or editing a `student`/`lesson`/`teacher`, you can select multiple tags that belong to the respective category.

Tables/Models:
* `Tag` fields: `name` `category`
* `Tagging` (joint table) fields: `tag_id` `taggable_id` `taggable_type`
* `Client` fields: anything
* `Lesson` fields: anything
* `Student` fields: anything

# Step 1. Tags and Taggings

console
```
rails g scaffold tags name category --no-helper --no-assets --no-controller-specs --no-view-specs --no-test-framework --no-jbuilder
rails g migration create_taggings tag:references taggable:references{polymorphic}
```

tag.rb
```
class Tag < ApplicationRecord
  validates :name, :category, presence: true
	validates :name, length: {minimum: 1, maximum: 25}, uniqueness: { scope: :category, message: "uniquene per category" }
  
  def to_s
    name
  end

  CATEGORIES = [:student, :lesson, :teacher]
  def self.categories
    CATEGORIES.map { |category| [category, category] }
  end
  has_many :taggings, dependent: :destroy
end
```
tagging.rb
```
class Tagging < ApplicationRecord
  belongs_to :taggable, polymorphic: true
  belongs_to :tag
end
```

tags_controller.rb - nothing special. Regular CRUD

taggings_controller.rb - not needed

# Step 2. Install Selectize.js

To select multiple tags we will use `selectize.js`.

* [official docs](https://selectize.github.io/selectize.js/){:target="blank"}
* [Selectize Yarn package](https://yarnpkg.com/package/selectize){:target="blank"}

console
```
yarn add selectize
```
app/javascript/packs/application.js - add these on the bottom
```
require("selectize")
require("packs/tags")
```
app/javascript/packs/tags.js - create this file
```
$(document).on("turbolinks:load", function() {
  $(".selectize-tags").selectize({
    create: function(input, callback) {
      $.post('/tags.json', { tag: { name: input } })
        .done(function(response){
          console.log(response)
          callback({value: response.id, text: response.name });
        })
    }
  });
});
```

# Step 3. Make any model taggable. Example - `Student`

student.rb - add relationships
```
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
```
students_controller.rb - whitelist multiple tags
```
  def student_params
    params.require(:student).permit(:name, tag_ids: [])
  end
```
students/_form.html.erb - input multiple tags with selectize
```
  <%= f.select :tag_ids, Tag.where(category: "student").pluck(:name, :id), {}, { multiple: true, class: "selectize-tags" } %>
```
student/show - display tags
```
<% @student.tags.each do |tag| %>
  <%= tag.name %>
<% end %>
```

# That's it! Now you have mastered THREE different approaches to using polymorphism

This tutorial does not cover creating NEW tags with selectize. Good idea for the future? 
