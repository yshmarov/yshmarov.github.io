---
layout: post
title: "Typesense search in a Rails app"
tags: typesense search rails
---

### 1. Install Typesense, interact with API, search Posts

[Install Typesense](https://typesense.org/docs/guide/install-typesense.html) and start server on port 8108:

```sh
brew install typesense/tap/typesense-server@27.1
curl http://localhost:8108/health
brew services start typesense-server@27.1

# brew services stop typesense-server@27.1
```

In your Rails app, install gem [typesense-ruby](http://github.com/typesense/typesense-ruby)

```
bundle add typesense
```

Initialize the typesense client:

```ruby
# config/initializers/typesense.rb
TYPESENSE_CLIENT = Typesense::Client.new(
  nodes: [{
    host: ENV.fetch('TYPESENSE_HOST', 'localhost'),
    port: ENV.fetch('TYPESENSE_PORT', '8108'),
    protocol: ENV.fetch('TYPESENSE_PROTOCOL', 'http')
  }],
  api_key: ENV.fetch('TYPESENSE_API_KEY', 'xyz'),
  connection_timeout_seconds: 2
)
```

Create a service to interact with the Typesense API. In this case, we use Typesense only for `Posts` model, and attributes `title` and `body`:

```ruby
# app/services/typesense_service.rb
class TypesenseService
  class << self
    # create an empty "table" of posts in typesense with attributes "title", "body", "created_at"
    # TypesenseService.create_schema
    def create_schema
      TYPESENSE_CLIENT.collections.create({
                                            name: 'posts',
                                            fields: [
                                              { name: 'title', type: 'string' },
                                              { name: 'body', type: 'string' },
                                              { name: 'created_at', type: 'int64' }
                                            ],
                                            default_sorting_field: 'created_at'
                                          })
    end

    # get info about the current state of the posts "table"
    def get_schema
      TYPESENSE_CLIENT.collections['posts'].retrieve
    end

    # drop "posts" table from typesense
    def delete_schema
      TYPESENSE_CLIENT.collections['posts'].delete
    end

    # dump all indexed posts data as a text blob
    def export_documents
      TYPESENSE_CLIENT.collections['posts'].documents.export
    end

    # find an indexed post by id
    def retrieve_document(id)
      TYPESENSE_CLIENT.collections['posts'].documents[id.to_s].retrieve
    end

    # see how many posts are actually indexed
    def documents_count
      search_posts('')['out_of']
    end

    # CREATE - use in Active Record callback
    def index_post(post)
      TYPESENSE_CLIENT.collections['posts'].documents.create({
                                                               id: post.id.to_s,
                                                               title: post.title || '',
                                                               body: post.body || '',
                                                               created_at: post.created_at.to_i
                                                             })
    end

    # UPDATE - use in Active Record callback
    def update_post(post)
      TYPESENSE_CLIENT.collections['posts'].documents[post.id.to_s].update({
                                                                             title: post.title || '',
                                                                             body: post.body || '',
                                                                             created_at: post.created_at.to_i
                                                                           })
    end

    # DESTROY - use in Active Record callback
    def delete_post(post_id)
      TYPESENSE_CLIENT.collections['posts'].documents[post_id.to_s].delete
    end

    # Make an API call to search posts in the typesense index
    def search_posts(query, options = {})
      search_parameters = {
        q: query,
        query_by: 'title,body',
        sort_by: 'created_at:desc',
        per_page: options[:per_page] || 10,
        page: options[:page] || 1
      }

      TYPESENSE_CLIENT.collections['posts'].documents.search(search_parameters)
    end
  end
end
```

Here's a rake task to create a Typesense table of Posts and add all Posts from our ActiveRecord Model/Postgres to the Typesense database

```ruby
# lib/tasks/typesense.rake

# rails typesense:setup
namespace :typesense do
  desc 'Create Typesense schema and index all posts'
  task setup: :environment do
    TypesenseService.create_schema
    Post.find_each do |post|
      TypesenseService.index_post(post)
    end
  end
end
```

Run `rails typesense:setup` in the console to trigger the task, or manually run the commands in the `rails console`.

Now you can search posts with Typesence:

```ruby
# rails c
result = TypesenseService.search_posts("hotwir")
# or
result = TypesenseService.search_posts("hotwir", per_page: 5, page: 2)
```

Next, you want to keep the Typesense posts index in sync!

Add the callbacks to the `Post` model:

```ruby
# app/models/post.rb
 after_create_commit do
    TypesenseService.index_post(self)
  end

  after_update_commit do
    TypesenseService.update_post(self)
  end

  after_destroy_commit do
    TypesenseService.delete_post(id)
  end
```

You can also make CURL requests to the Typesense server using your API key (`xyz` is the default key).

```sh
curl -H "X-TYPESENSE-API-KEY: xyz" http://localhost:8108/collections/posts/documents/2
curl -H "X-TYPESENSE-API-KEY: xyz" http://localhost:8108/stats.json
```

### 2. Search UI. Routes, Controller, Views

Create a route to search for posts at `localhost:3000/posts/search`.

```ruby
# config/routes.rb
resources :posts do
  collection do
    get :search
  end
end
```

Make a search request to your Typesense server and handle the result:

```ruby
# app/controllers/posts_controller.rb
  def search
    results = if params[:query].present?
                TypesenseService.search_posts(
                  params[:query],
                  page: params[:page],
                  per_page: params[:per_page] || 10
                )
              else
                { 'hits' => [] }
              end

    @posts = results['hits'].map do |hit|
      {
        id: hit['document']['id'],
        title: hit['document']['title'],
        description: hit['document']['description'],
        highlight: hit['highlights']
      }
    end
    respond_to do |format|
      format.json { render json: @posts }
      format.html
    end
  end
```

You can now make a CURL request to your `search.json` endpoint to get results.

```sh
curl http://localhost:3000/posts/search.json?q=hotwire
```

🚨 If the endpoint does not require authentication, be sure to add rate limiting!

Basic views (assuming you have Hotwire installed):

```ruby
# app/views/posts/search.html.erb
<%= form_with url: search_posts_path, method: :get, data: { turbo_frame: :results} do |f| %>
  <%= f.text_field :query, value: params[:query], autofocus: true, autocomplete: 'off', autocorrect: 'off', oninput: "this.form.requestSubmit()" %>
  <%= f.submit %>
<% end %>

<br>

<%= turbo_frame_tag :results, target: "_top", data: { turbo_action: "advance" } do %>
  <% if @posts.any? %>
    <% @posts.each do |result| %>
      <%= render "search_result", result: %>
    <% end %>
  <% elsif params[:query].present? %>
    No results found for "<%= params[:query] %>"
  <% end %>
<% end %>
```

```ruby
# app/views/posts/_search_result.html.erb
<%= link_to post_path(result[:id]) do %>
  <h3>
    <% if result[:highlight]&.find { |h| h["field"] == "title" } %>
      <%= sanitize result[:highlight].find { |h| h["field"] == "title" }["snippet"] %>
    <% else %>
      <%= result[:title] %>
    <% end %>
  </h3>

  <% if result[:description].present? %>
    <p><%= result[:description] %></p>
  <% end %>

  <% if result[:highlight]&.find { |h| h["field"] == "body" } %>
    <div>
      <%= sanitize result[:highlight].find { |h| h["field"] == "body" }["snippet"] %>
    </div>
  <% end %>
<% end %>
```

Voila! Now you have a Typesense search server running locally, connected to search in your Rails app!

⚠️ Typesense is working on [gem typesense-rails](https://github.com/typesense/typesense-rails) that will make interacting with the API even easier. I'm really looking forward for that. In the meantime, I think my `TypesenseService` approach is very good.