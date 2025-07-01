---
layout: post
title: Ruby AI. Vector (semantic) search with embeddings
author: Yaroslav Shmarov
tags: rubyllm neighbour pgvector ai
thumbnail: /assets/static-pages/yaro-avatar.png
---

Best ways to search in Rails, from simple to advanced:

1. SQL `ILIKE`
2. gem ransack `name_or_description_cont`
3. [gem pg_search]({% post_url 2021-06-06-install-gem-pg_search %}) - advanced Postgres search
4. indexed search with typesense/elasticsearch/algolia
5. AI search with embeddings

AI search lets you search by "meaning", not by keywords!

How AI search works:

1. create embeddings: turn texts into vectors
2. search embeddings with gem neighbour

## Install dependencies

```ruby
# Gemfile
# pg extension to enable vectors
# https://github.com/pgvector/pgvector-ruby
gem "pgvector"
# vector search
# https://github.com/ankane/neighbor
gem "neighbor"
# create vectors
# https://github.com/crmne/ruby_llm
gem "ruby_llm"
```

```sh
brew install pgvector
```

If it doesn't work, run

```sh
mkdir -p ~/tmp
cd ~/tmp
git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git
cd pgvector

# Build and install for DocumentgreSQL 16
make USE_PGXS=1 PG_CONFIG=/opt/homebrew/opt/postgresql@16/bin/pg_config
sudo make USE_PGXS=1 PG_CONFIG=/opt/homebrew/opt/postgresql@16/bin/pg_config install

# Restart DocumentgreSQL
brew services restart postgresql@16
```

```ruby
# config/initializers/neighbor.rb
Neighbor::PostgreSQL.initialize!
```

Run migrations:

```ruby
rails g migration InstallNeighborVector
rails g migration AddEmbeddingToDocuments
rails g model Document title content
```

```ruby
class InstallNeighborVector < ActiveRecord::Migration[7.1]
  def change
    enable_extension "vector"
  end
end
```

```ruby
class AddEmbeddingToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :embedding, :vector, limit: 1536, if_not_exists: true
  end
end
```

## Create embeddings:

```ruby
# app/models/document.rb
  validates :title, presence: true
  validates :content, presence: true

  has_neighbors :embedding, dimensions: 1536
  before_save :generate_embedding, if: -> { saved_change_to_title? || saved_change_to_content? }

  scope :search_by_similarity, -> (query_text) {
    query_embedding = RubyLLM.embed(query_text).vectors

    # distance: :inner_product
    nearest_neighbors(:embedding, query_embedding, distance: :cosine).limit(5)
  }

  # def text_for_embedding
  #   <<~EOS
  #     Title: #{title}
  #     Content: #{content}
  #   EOS
  # end

  def generate_embedding
    text_for_embedding = [
      "Title: #{title}",
      "Content: #{content}",
    ].compact.join("\n---\n")

    begin
      self.embedding = RubyLLM.embed(text_for_embedding).vectors
    rescue RubyLLM::Error => e
    end
  end
```

## Perform search:

Console

```ruby
Document.create(content: "Company HR policy: Employees must...")
Document.create(content: "Company internal documentation: ...")

documents = Document.search_by_similarity("What is the company's remote work policy?")
documents.each { |document| puts "- #{document.content}" }
```

Controller

```ruby
# app/controllers/documents_controller.rb
def index
  @documents = if params[:q].present?
    Document.all.search_by_similarity(params[:q])
  else
    Document.all
  end
end
```

## Make it work on CI

```diff
# ci
-image: postgres:11-alpine
+image: pgvector/pgvector:pg16
```

## Next steps

- Rate limiting; do not do typeahead search (too many requests & token$)
- Add caching for popular queries (Query `string` & `embedding` pairs)
- Let user see his recent searches / recently visited (might have to do fewer search queries)

## Inspired by

https://d-caponi1.medium.com/getting-set-up-with-vector-databases-in-rails-8-ac1fa2fb5b48
https://medium.com/@mauricio/how-to-add-recommendations-to-a-rails-app-with-pgvector-and-openai-881d87915fb2
https://liambx.com/blog/semantic-search-rails-neighbor-gem
