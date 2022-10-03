Turbo Frames: frame navigation animation

### 1. Initial setup

```ruby
# db/seeds.rb
5.times do
  Movie.create(
    title: Faker::Movie.title,
    description: Faker::Movie.quote,
    year: rand(1920..2022)
  )
end
```

```ruby
# CLI
bundle add faker
rails g scaffold Movie title description:text year:integer
rails db:migrate
rails db:seed
```

### 2. Click on movie to show details

Add an empty `turbo_frame_tag` to the index page, where the movie details will be rendered

```ruby
# app/views/movies/index.html.erb
<% @movies.each do |movie| %>
  <%= render movie %>
<% end %>

<%= turbo_frame_tag :movie_details do %>
  Select a movie for more details...
<% end %>
```

```ruby
# app/views/movies/_movie.html.erb
<%= link_to movie.title, movie, data: { turbo_frame: "movie_details" } %>
```

```ruby
# app/views/movies/show.html.erb
<%= turbo_frame_tag :movie_details do %>
  <%= @movie.year %>
  <%= @movie.description %>
<% end %>
```

### 2. Loading animation

```css
/* app/assets/stylesheets/application.css */
.hidden { display: none; }
```

https://turbo.hotwired.dev/reference/events

```ruby
rails g stimulus turbo-placeholder
```

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-placeholder"
export default class extends Controller {
  static targets = ['content', 'loading'];

  displayLoading(event) {
    this.loadingTarget.classList.remove('hidden');
    this.contentTarget.classList.add('hidden');
  }

  displayContent() {
    this.loadingTarget.classList.add('hidden');
    this.contentTarget.classList.remove('hidden');
  }
}
```

```ruby
# app/views/movies/index.html.erb
<div data-controller="turbo-placeholder" 
     data-action="
       turbo:before-fetch-request@document->turbo-placeholder#displayLoading
       turbo:before-fetch-response@document->turbo-placeholder#displayContent
     ">

  <% @movies.each do |movie| %>
    <%= render movie %>
  <% end %>

  <%= turbo_frame_tag :movie_details, data: { turbo_placeholder_target: "content" } do %>
    Select a movie for more details...
  <% end %>

  <div class="hidden" data-turbo-placeholder-target="loading">
    Loading...
  </div>
</div>
```

### 3. 

```diff
# app/views/movies/index.html.erb
<div data-controller="turbo-placeholder" 
     data-action="
-       turbo:before-fetch-request@document->turbo-placeholder#displayLoading
       turbo:before-fetch-response@document->turbo-placeholder#displayContent
     ">
```

```ruby
# app/views/movies/_movie.html.erb
<%= link_to movie.title, movie,
            data: { turbo_frame: "movie_details",
                    action: "turbo:click->turbo-placeholder#displayLoading" } %>
```

Based on [Mike Wilson's great article](https://www.mikewilson.dev/posts/using-hotwire-with-rails-for-a-spa-like-experience/)
