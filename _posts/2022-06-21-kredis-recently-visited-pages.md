---
layout: post
title: "Gem Kredis #2 - recently visited pages"
author: Yaroslav Shmarov
tags: ruby-on-rails redis kredis
thumbnail: /assets/thumbnails/redis.png
---

Final result:
* whenever you visit a movie page, it will be added to "recently opened movie pages" list
* 5 last opened movies will be saved in the list
* list is unique for each user

![kredis-recently-viewed.gif](/assets/images/kredis-recently-viewed.gif)

### 1. Initial setup for the app

First, let's *mimic* a `current_user` without installing `Devise`:

```shell
# Terminal
rails g model User session:string
rails db:migrate
```

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_user

  def current_user    
    @current_user ||= User.find_or_create_by(session: session.id.to_s)
  end
end
```

Next, lets add a Movies table:

```shell
# Terminal
./bin/rails g scaffold movie title
rails db:migrate
bundle add faker
rails c
20.times { Movie.create!(title: Faker::Movie.title) }
```

Install kredis:

```shell
# Terminal
./bin/bundle add kredis
./bin/rails kredis:install
```

### 2. recently opened pages with Kredis

`Kredis.unique_list` is basically an array with a max number of elements:

```ruby
ab = Kredis.unique_list("recent")
ab.limit = 5
ab.elements
# []
ab.prepend(Movie.first.id)
# ["1"]
ab.prepend(Movie.last.id)
# ["1", "20"]
ab.elements
# ["1", "20"]
ab.prepend(20)
# ["20", "1"]
ab.remove(["20", "1"])
# []
```

Add a kredis column association to `User`:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  kredis_unique_list :recent_movies, limit: 5
end
```

Next, when the user opens the page, `prepend` (add to start of list) the `movie.id` to `current_user.recent_movies`:

```ruby
# app/controllers/movies_controller.rb
class MoviesController < ApplicationController
  def show
    @movie = Movie.find(params[:id])
    current_user.recent_movies.prepend(@movie.id)
    # current_user&.recent_movies.clear # clear array
    # current_user.recent_movies.remove(current_user.recent_movies.elements) # stupid clear array
  end
end
```

Display the list:

```ruby
# app/views/users/_recently_opened_movies.html.erb
<% current_user.recent_movies.elements.each do |movie| %>
  <% movie = Movie.find(movie) %>
  <%= link_to movie.title, movie_path(movie) %>
<% end %>
```

That's it!
