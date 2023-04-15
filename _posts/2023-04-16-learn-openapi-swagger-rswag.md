---
layout: post
title: API documentation with OpenAPI and Swagger using gem Rswag 
author: Yaroslav Shmarov
tags: ruby-on-rails rails-api swagger openapi
thumbnail: /assets/thumbnails/api.png
---

Good API documentation is crucial for helping others adopt and use your public API.

[OpenAPI](https://swagger.io/solutions/getting-started-with-oas/) (previously Swagger) offers a standard for API documentation. OpenAPI documenation is basically a structured `.yml` manifest file. Swagger UI is a tool that reads your `.yml` file and displays it in a fancy UI.

Swagger UI Example:

![swagger ui pet store example](/assets/images/swagger-ui.png)

In an ideal scenario, the process of API development would look like this:
1. Code your API
2. Write API tests
3. Auto-generate API documentation (the `.yml` file) based on tests
4. Feed the generated yaml file to a API UI tool (for example, Swagger UI), where end users can play with the data.

It is totally possible and okay to host your API docs separately from your Ruby app.

There seem to be a few approaches to creating API documentation (`.yml` file):
- Write API docs **manually** (or with ChatGPT help!)
- **generate from Rspec** tests that are written in a specific format using [gem rswag](https://github.com/rswag/rswag) or [gem rspec_api_documentation](https://github.com/zipmark/rspec_api_documentation) or [gem rspec-openapi](https://github.com/exoego/rspec-openapi)
- generate from annotating controllers with a specific DSL using [gem apipie-rails](https://github.com/Apipie/apipie-rails)

### 1. Install Rswag

```ruby
# Gemfile

# display Swagger UI
gem "rswag-ui"
# make API requests from Swagger UI
gem "rswag-api"
```

Run the installation scripts:

```sh
bundle
rails g rswag:api:install
rails g rswag:ui:install
```

Set the path to access the api docs;

In this case it would be `https://localhost:3000/docs/api`;

Optionally require authentication to access the API docs:

```ruby
# config/routes.rb
  authenticated :user do
    mount Rswag::Ui::Engine => "/docs/api"
    mount Rswag::Api::Engine => "/docs/api"
  end
```

Set the path to your OpenAPI manifest file:

```ruby
# config/initializers/rswag_ui.rb
  c.swagger_endpoint "/docs/api/v1/openapi.yaml", "API V1 Docs"
```

### 2. Add your custom branding to the UI

Check the official docs for that. I just recently personally pushed a PR to explain how to do it:

[Customizing the swagger-ui](https://github.com/rswag/rswag#customizing-the-swagger-ui)

### 3. Generate OpenAPI manifest

**You can leverage ChatGPT for this! Prompt that I use:**

![chatgpt-openapi-generation](/assets/images/chatgpt-openapi-generation.png)

**Text version of the prompt:**

*You need to generate an OpenAPI manifest file. An API request looks like this*

```sh
curl -X GET "http://localhost:3000/api/v1/posts/1" -H "Authorization: Bearer mySecretToken"
```
*and a response looks like this*

```json
{
  "id": 0,
  "title": "string",
  "created_at": "2023-04-15T19:32:53.182Z",
  "updated_at": "2023-04-15T19:32:53.182Z",
  "url": "string"
}
```

*You should include `UnauthorizedError` and `RecordNotFound` responses. In the future there will be many more API endpoints, so you should make the manifest file reusable from the start.*

*Do not forget to abstract schema and include bearer authentication*

**Keep in mind: ChatGPT does not get everything right. Read through the generated responses attentively and be ready to solve inconsistencies!**
