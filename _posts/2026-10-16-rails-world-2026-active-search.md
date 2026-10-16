---
layout: post
title: "Rails World 2026: Active Search (Donal McBreen)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails search database
thumbnail: /assets/thumbnails/youtube/OlzIyVzmMgI.jpg
image:
  path: /assets/images/youtube/OlzIyVzmMgI.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Active Search (Donal McBreen)"
youtube_id: OlzIyVzmMgI
---

Donal McBreen from 37signals introduced **Active Search**: a full-text search framework for Rails with one API and pluggable adapters, the same idea as Active Record or Active Job. If you have ever hand-rolled `pg_search`, wired up Elasticsearch, or switched search backends between SaaS and self-hosted builds, this is worth a look.

## Key ideas

### One API, many stores

Two kinds of adapters:

- **Databases with full-text features:** SQLite (FTS5), PostgreSQL (tsvector), MySQL (FULLTEXT)
- **Search engines:** Elasticsearch, OpenSearch, Solr, Meilisearch, Typesense, Manticore, Redis Search

37signals uses it with Elasticsearch in Basecamp. In Fizzy, which is open source and can be self-hosted, it switches between MySQL and SQLite, so you can read [basecamp/fizzy](https://github.com/basecamp/fizzy) for a real-world example.

### Setup

```ruby
# Gemfile
gem "rails-active_search"
```

```bash
rails active_search:install ADAPTER=elasticsearch
rails generate active_search:index Article title body:text status:string views:integer
rails active_search:index:create INDEX=articles
```

The installer writes `config/search.yml` (adapter per environment) and `config/search.rb`, where indexes are defined. The generator adds an index definition and a `has_search` line to the model:

```ruby
# config/search.rb
ActiveSearch.define_index(:articles) do
  text :title
  text :body
  string :status
  integer :views
end

# app/models/article.rb
class Article < ApplicationRecord
  has_search
end
```

`text` fields are full-text searched. Other types like `string` are for filtering. There is no migration system for search engine indexes yet: adding a field to an existing index is up to you.

### Indexing

`has_search` adds callbacks: create, update or destroy enqueues an Active Job that sends the record to the index. Use `has_search async: false` to index inline.

Under the hood, the index turns the record into a **document** (an id plus a hash of fields) and the store adapter translates it into whatever its engine needs: JSON for Elasticsearch, an upsert for SQLite. By default it calls a method per field (`article.title`). When that doesn't fit, pass a serializer:

```ruby
has_search serializer: :to_search_document
```

Donal's example truncated the body to keep the index small, and derived a `status` from `published_at`.

### Searching

The query API chains like an Active Record relation:

```ruby
Article.search("rails")
  .filter(status: "published", views: 100..)
  .reject(status: "draft")
  .results
```

`results` is enumerable and returns **real Active Record models**, loaded from your database. The results object also carries metadata: total count, relevance score, raw fields and highlights.

### Polymorphic indexes

One index can hold several models, like articles and comments together. Declare it `polymorphic: true` and it gets `record_type` and `record_id` fields. Models join with `has_search index: :records`, often with a serializer (comments borrow their article's title). `ActiveSearch.index(:records).search(...)` returns a mix of both. `Article.search("...", index: :records)` adds a hidden `record_type` filter so you only get articles back.

### Database adapters

On SQLite, Postgres or MySQL, a `rails generate active_search:document articles` generator creates an `ArticleDocument` model (a normal `ApplicationRecord`) and a migration. Data is denormalized into that table because a custom serializer can pull values from anywhere. Since it is a normal model, the usual multi-database tools work if you want search in its own database.

Each database does it differently: SQLite adds an FTS5 virtual table, Postgres adds tsvector columns with GIN indexes, MySQL adds a FULLTEXT index.

### Escape hatches

- `to_native_query` shows the query as built: a hash for search engines, an **Active Record relation** for database adapters, which you can join or merge into your own queries.
- `native { |query| ... }` lets you change the query before it's sent, for engine-specific features like custom ranking.
- `capabilities` tells you what the current adapter supports. Search engines vary more than databases do: for example, highlighting works everywhere except MySQL.

It's **alpha** software and the API is not settled.

## My takeaways

- If you run SQLite in development and Postgres or Elasticsearch in production, Active Search gives you the same search code in both.
- Read Fizzy's source before adopting it. It's the best example of the gem in production.
- Use a custom serializer from the start, so the index only holds what you actually search and filter on.
- Expect breaking changes while it's alpha. Pin the version and send Donal feedback.

Watch the full talk: [Active Search](https://www.youtube.com/watch?v=OlzIyVzmMgI)
