---
layout: post
title: "Rails World 2026: Kamal Deep Dive (Josef Strzibny)"
author: Yaroslav Shmarov
tags: rails-world conference kamal deployment docker
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: CsWQD81i5-c
---

Josef Strzibny, who wrote a book and a video course on Kamal, followed a single `kamal deploy` from your laptop all the way to a proxied HTTP request on the server. If you deploy with Kamal and have ever wondered what all that scrolling output actually means, this is the talk.

## Key ideas

### Two halves: the CLI and kamal-proxy

Kamal is the Ruby CLI that runs on your machine. **kamal-proxy** is a small Go program that runs on each server. The CLI never writes config files for the proxy. Every instruction is a `docker exec` into the proxy container, sent over SSH.

Your app is described as **roles** (`web` is the primary one, `job` or anything else you add) plus **accessories** (database, headless browser, etc.) that have their own lifecycle.

### SSH and commands as arrays

- The CLI is built on **Thor**, the same library behind Rails generators.
- Remote execution goes through **SSHKit** (of Capistrano fame), with a small DSL on top that adds `on(roles)` alongside `on(hosts)`.
- Every command in the `Kamal::Commands` namespace is just a Ruby array of tokens, like `[:docker, :run, ...]`. Piping, chaining and wrapping in `sh -c` are all array operations. The array is only turned into a shell string at the last moment when SSHKit executes it.
- Secrets are wrapped in a sensitive object that redacts itself when inspected or logged.
- Kamal patches SSHKit so that a failure on one host does not abort the others: it runs everywhere, collects all the errors, then reports. SSH connections are pooled and reused across the many small commands.

### Building and pushing images

`docker buildx build` uses the **docker-container** builder driver, which spins up a BuildKit container. That is what gives you multi-arch builds and remote builders. A remote builder is the same thing on another host that already has Docker.

The newer **local registry** option is just a `registry` image running in a container on your machine. The interesting part is how servers reach it: Kamal opens an SSH **remote port forward** (the reverse of the `ssh -L` you use to reach a remote database), so servers can `docker pull` from what looks like a local port.

### Registering with the proxy

A deploy ends with something like:

```bash
docker exec kamal-proxy kamal-proxy deploy myapp-web --target <container>:80
```

plus every option you configured (TLS, buffering, logging). Because the config is passed imperatively, kamal-proxy persists it to a named volume so it survives its own restart.

Zero-downtime is blue-green: boot the new container, let the proxy health-check it, switch traffic, drain the old one. Assets from both versions are copied into one shared volume (without overwriting), so old and new containers can serve each other's fingerprinted files during the switch. The deploy lock is literally a directory created on the server.

### The barrier

With several hosts, Kamal uses a **barrier** built on a `Concurrent::IVar` that can be set only once. All web containers start booting; the first one to pass its health check opens the barrier, and the other roles wait on it before starting their new version. If no web container boots, the barrier closes and the deploy halts. Rolling deploys over many hosts are a simple slice of the host list, by count or percentage.

### A little Go

Josef closed with a crash course in Go: **goroutines** and **channels**. kamal-proxy uses a ticker channel for health checks, buffers slow or large requests partly in memory and partly on disk, and drains on deploy by waiting for each in-flight request to finish or hit a deadline. Hijacked connections (WebSockets, so your Action Cable clients) are closed immediately instead of drained. Maintenance mode is a "pause" channel that waiting requests block on until it is closed.

## My takeaways

- When a deploy fails on one host, read the whole output. Kamal deliberately keeps going and reports every host's error together.
- If you don't want to run Docker Hub or GHCR just for deploys, try the local registry. Under the hood it is plain SSH port forwarding.
- If your app uses Action Cable, expect clients to reconnect on every deploy. kamal-proxy drops WebSocket connections instead of draining them.
- The Kamal codebase is small and readable. Start at `Kamal::Commands` and the healthcheck barrier if you want to understand your deploys.

Watch the full talk: [Kamal Deep Dive](https://www.youtube.com/watch?v=CsWQD81i5-c)
