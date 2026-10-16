---
layout: post
title: "Rails World 2026: Sharding Is Hard: Let's Make It Easier! (Tess Griffin)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails database postgresql sharding
thumbnail: /assets/thumbnails/youtube/yLoqg7UkryU.jpg
image:
  path: /assets/images/youtube/yLoqg7UkryU.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Sharding Is Hard: Let's Make It Easier! (Tess Griffin)"
youtube_id: yLoqg7UkryU
---

Tess Griffin from thoughtbot walked through sharding a Rails app whose single Postgres database has outgrown the biggest box money can buy. The example was a multi-clinic healthcare app, and the talk covered picking a shard key, routing queries with Rails or with a proxy like PgDog, and what to do about the queries that have to cross shards.

## Key ideas

### Measure first

Before sharding, find out why the database is struggling. Postgres can tell you whether you're read-heavy or write-heavy, which tables take the writes, and which tables got huge.

- **Slow reads** have a cheaper fix: replicas. But every replica still holds every row, and the primary still takes every write.
- **Slow writes and giant tables** are what sharding fixes. Every machine takes a slice of the writes and holds a slice of the rows.

### Choosing the shard key

You pick one column, and its value decides which machine each row lives on. A query that carries the shard key goes to one shard. A query that doesn't goes to **all** of them, and then sharding buys you nothing.

In the healthcare app, visits and audit logs were the tables on fire (every data access gets an audit log entry for HIPAA). Tess tried each candidate:

- **Patient:** patients belong to several clinics, and many queries don't carry a patient at all.
- **Practitioner:** same problem, and almost nothing references a practitioner.
- **Visit:** spreads the load evenly, but a visit owns almost nothing, so every query crosses shards.
- **Clinic:** almost everything hangs off a clinic. Joins work, transactions are plain single-database transactions, and a bug or breach stays inside one shard's clinics.

Her rule: **shard on the data that's easiest to separate.** Shared reference data (remedies, in her example) gets copied to every shard. Things that belong to no clinic (billing, admins, plans, feature flags) stay on the primary. A customer that needs real isolation can get a shard of its own.

### Mapping clinics to shards

- **Compute it** with a hash function (`clinic_id % n` is the simple version). The catch: change `n` and every clinic moves, and you can't move one clinic on its own.
- **Store it** in a small table: one row per clinic, with its shard. You decide placement, and moving a huge clinic onto its own shard is a single update. The trade-off is that every lookup depends on that table.

### Routing in Rails

Rails' built-in sharding gives you the primitive: an abstract model that `connects_to` the shards (a writer and a replica each), and `connected_to(shard:)` around the work. The mistake is sprinkling that through controllers and jobs. Tess kept the routing in one place, including for background jobs:

```ruby
class ApplicationJob < ActiveJob::Base
  around_perform do |job, block|
    clinic_id = job.arguments.first.fetch(:clinic_id)
    shard = ShardMap.shard_for(clinic_id)

    TenantRecord.connected_to(shard: shard) { block.call }
  end
end
```

My sketch of the pattern she described: one `around_perform` resolves the shard from a `clinic_id` argument, and a job enqueued without a clinic raises instead of querying the wrong shard. Keep Solid Queue's tables on the primary or in their own database, and don't shard them.

### Or let a proxy do it

A proxy sits between the app and the database and speaks plain SQL. On Postgres that's [PgDog](https://github.com/pgdogdev/pgdog). On MySQL it's Vitess, with PlanetScale as the managed version. Your `database.yml` points at the proxy and the app goes back to believing there's one database. You pass it the sharding key per transaction with a `SET`, and there's no shard map or resolver to maintain. A proxy can also re-shard while the app keeps serving.

### Cross-shard reads and writes

- **Cross-shard reads:** run the same query on each shard and merge the results (scatter-gather). A proxy fans out for you.
- **Cross-shard writes:** atomic transactions across machines need two-phase commit. Postgres has `PREPARE TRANSACTION`, and prepared transactions survive crashes. But if your code dies between prepare and commit, every shard sits holding its locks, and Postgres won't clean that up. You'd have to build the recovery plumbing yourself. A proxy can run 2PC for you, but the locks and the slowest-shard waits are still there.

As Tess put it, "a proxy can hide the hard parts. It doesn't remove them."

## My takeaways

- Find out whether reads or writes are the bottleneck first. Replicas are much cheaper.
- Choose the shard key that keeps each tenant's work in one place. In most multi-tenant Rails apps that's the account or organization.
- Store the tenant-to-shard mapping in a table. It pays for itself the first time one big customer needs its own shard.
- Keep routing in a single place, and look at PgDog before writing the plumbing yourself.

Watch the full talk: [Sharding Is Hard: Let's Make It Easier!](https://www.youtube.com/watch?v=yLoqg7UkryU)
