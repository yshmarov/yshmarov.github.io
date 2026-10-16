---
layout: post
title: "Rails World 2026: A deep dive into Solid Cable (Nick Pezza)"
author: Yaroslav Shmarov
tags: rails-world conference action-cable solid-cable hotwire
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: 9WEABvHEKws
---

Nick Pezza wrote and maintains Solid Cable, the database-backed Action Cable adapter that became the Rails 8 default. The talk covers how it works, benchmarks it against Redis and the native Postgres adapter, and shows the changes in **Solid Cable 4.1** that bring it much closer to Redis under load.

## Key ideas

### Why it exists

Before Rails 8 you had three adapters. **Async** only works inside one process. **Postgres** uses `LISTEN/NOTIFY`, which caps payloads at about 8 KB (a problem if you broadcast big chunks of Turbo Stream HTML) and is useless if you're on SQLite or MySQL. So most apps ran **Redis** just for Action Cable. Nick had already moved caching to Solid Cache and wanted Redis gone entirely.

### How it works

Low tech: **polling**. Broadcasting is a single `insert` into a messages table (skipping callbacks, validations and the transaction wrapper). A listener thread loops forever: fetch messages with an ID greater than the last one seen for the watched channels, deliver them, sleep 100 ms by default. Version 1 was about 112 lines of code.

Things added since:

- **Auto-trimming**. Instead of a cron, each write has a small chance of deleting a batch of expired messages, tuned so trimming capacity is roughly twice the write rate.
- **Hashed channel names**. Channels are stored as a SHA-256-derived integer, so the index is smaller and lookups are cheaper.
- **Per-channel "last seen" IDs**. A new subscription used to be able to receive older messages still in the table. Now each channel gets its own starting point, tracked in a concurrent map.

### Benchmarks and the 4.1 fixes

Nick used Grafana k6 on a 2-CPU, 8 GB box, with three scenarios: constant load, thundering herd (everyone reconnects at once, like after a deploy) and "lecture" (one channel, many subscribers). The scripts live in the `bench` directory of the repo.

At low load all adapters were close. Under heavy load Solid Cable on Postgres and MySQL fell behind. Profiling found:

1. Config was re-read and re-parsed from `cable.yml` on every broadcast and every poll. Now it's memoized.
2. Channel names were re-hashed on every poll. Now they're hashed once on subscribe.
3. Every broadcast was its own `INSERT`. Now a broadcaster thread collects messages until a batch size or a max delay is hit, then writes them with one `insert_all`.
4. In Action Cable itself, even the default stream handler pushed every message through the worker thread pool. Now that pool is only used when you pass a custom callback. This fix ships with the upcoming Rails release and helps **every** adapter.

The results at 1,000 users: SQLite edged past Redis on throughput (1,048 msg/s), Postgres went from 609 to about 1,000 and MySQL from 491 to 961. The lecture test at 750 subscribers and 10 messages per second, which every adapter used to fail, now passes.

### Tuning knobs

```yaml
# config/cable.yml
production:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

Dropping `polling_interval` to 25 ms improved latency noticeably at low and medium load, but at saturation the extra reads hurt Postgres and MySQL, while SQLite kept improving. Auto-trimming (`autotrim`, on by default) cost almost nothing in throughput.

### ChronoCable

Action Cable doesn't guarantee delivery order, because messages go through a thread pool. That matters when you stream LLM output token by token. Nick's new, work-in-progress gem **chrono_cable** stores a per-channel sequence number with each message. The browser buffers anything that arrives early, fetches the missing range from history, and catches up after a reconnect.

```ruby
stream_from "chat_42", deliver_in_order: true
```

```erb
<%= turbo_stream_from "chat_42", data: { deliver_in_order: true } %>
```

## My takeaways

- If Redis is in your stack only for Action Cable, upgrade to Solid Cable 4.1 and try removing it.
- Measure before tuning `polling_interval`. Lower helps latency at low traffic but can hurt a busy Postgres or MySQL.
- If you stream LLM responses over Turbo Streams and see garbled text, out-of-order delivery is a likely cause. Keep an eye on ChronoCable.

Watch the full talk: [A deep dive into Solid Cable](https://www.youtube.com/watch?v=9WEABvHEKws)
