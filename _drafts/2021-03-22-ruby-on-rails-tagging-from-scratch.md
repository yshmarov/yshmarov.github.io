---
layout: post
title: "Tagging from scratch in Rails"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails tags
thumbnail: /assets/thumbnails/tags-thumbnail.png
---

### TODOYARO

# 1. Migrations & configuration

console
```
rails g migration create_tags name
rails g migration create_course_tags course:references tag:references
```
course.rb
```
	has_many :course_tags, dependent: :destroy
	has_many :tags, through: :course_tags
```
tag.rb
```
class Tag < ApplicationRecord
	has_many :course_tags
	has_many :courses, through: :course_tags
	validates :name, length: {minimum: 1, maximum: 25}, uniqueness: true
	def to_s
		name
	end
```
course_tag.rb
```
  belongs_to :tag
  belongs_to :course
```
routes.rb
```
  resources :tags
```
courses_controller.rb - add `tag_ids: []` to params
```
  params.require(:course).permit(:name, tag_ids: [])
```
tags_controller.rb
```
  class TagsController < ApplicationController
    def create
      @tag = Tag.new(params.require(:tag).permit(:name))
      if @tag.save
        render json: @tag
      else
        render json: {errors: @tag.errors.full_messages}
      end
    end
  end
```
rails c
```
Tag.create(name: "Programming")
Tag.create(name: "English")
Tag.create(name: "Literature")
```

# 2. Select tags with selectize js

```
yarn add selectize
```
app/assets/stylesheets/application.scss:
```
@import "selectize/dist/css/selectize";
@import "selectize/dist/css/selectize.default";
```
javascript/packs/application.js
```
require("selectize")
require("packs/tags")
```
javascript/packs/tags.js
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
course/form.html.haml
```
	= f.select :tag_ids, Tag.all.pluck(:name, :id), {}, { multiple: true, class: "selectize-tags" }
```
