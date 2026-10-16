---
layout: post
title: "Rails World 2026: Distributing Rails applications with ONCE (Kevin McConnell)"
author: Yaroslav Shmarov
tags: rails-world conference once self-hosting docker
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: eE4aVg15tbs
---

Kevin McConnell from 37signals compared SaaS with self-hosted distribution, then showed **ONCE**, the tool they built so that a customer can install a Rails app on their own server with one pasted command. The main point for Rails developers: a fresh `rails new` app already meets almost all of ONCE's requirements.

## Key ideas

### SaaS vs self-hosting

Neither model is better; the strengths of one are the weaknesses of the other.

- **Infrastructure**: with SaaS you control it and pay for it. Self-hosted customers bring their own hardware.
- **Data**: with SaaS you're responsible for security and backups. Self-hosted, the customer keeps the data, which can be a privacy win for them.
- **Visibility**: SaaS gives you logs and exception reports. Self-hosted gives you nothing, and Kevin advises against adding telemetry.
- **Scaling**: self-hosted apps only need to handle the biggest single customer. For Campfire, a mostly vanilla Rails app on SQLite on one modest server handled the largest installation they could imagine.
- **Control**: once someone has a working copy, you can't really gate what they do with it.
- **Customer effort**: self-hosting sounds harder. In practice, after thousands of Campfire sales, almost nobody contacted support because installation was hard.

### The ONCE tool

The model was a game cartridge: plug it in and it works. The only thing ONCE can't guess is the **hostname** (for the TLS certificate and for routing between apps on the same box), so it asks for that and nothing else.

```bash
curl https://get.once.com | sh
```

It installs Docker if needed, then lets you pick a built-in 37signals app (Campfire, Fizzy, Writebook...) or **any Docker image path**. The app-specific variant of the command goes straight to installing that app. In the demo, Kevin pasted the Fizzy command, typed a hostname, and ONCE fetched, configured and booted the app.

After install, ONCE opens a terminal dashboard showing your apps, traffic, visitors and resource use, with menus for settings, backups and updates. Under the hood each app gets its own Docker network, a container, and a persistent volume, behind a small proxy that handles TLS and routes by hostname.

### What your app needs

Four things:

1. Packaged as a Docker image.
2. Serves HTTP on port 80.
3. A health check endpoint at `/up`.
4. Persistent data in `/storage`.

A new Rails app has all of it. The generated Dockerfile uses **Thruster** on port 80, `/up` is built in, and ONCE mounts the same volume at both `/storage` and `/rails/storage`, so the default SQLite location just works. The default entrypoint runs `db:prepare` on boot, so a customer who upgrades from v1 to v2 gets pending migrations applied automatically. The SQLite database, Solid Cache and Active Storage's disk service all keep their data locally, inside that volume.

So shipping is: `rails new`, build features, push the image to a registry your customers can reach, share the install command.

### What ONCE gives your app

Environment variables:

- `SECRET_KEY_BASE`, unique per installation, so a signed cookie from one install is useless on another.
- `VAPID_PUBLIC_KEY` / `VAPID_PRIVATE_KEY` for Web Push.
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAILER_FROM_ADDRESS`, filled from an email settings screen where the customer pastes credentials from Postmark, SendGrid, Mailgun and so on. Fizzy's `production.rb` shows how to wire them up.
- `NUM_CPUS` when the customer limits CPU, so you can size worker processes.

Backups run daily and a month of archives is kept. Copying a live SQLite file can produce a corrupt copy, so by default ONCE briefly pauses the container. To avoid the pause, provide hooks:

- `/hooks/pre-backup`: Campfire uses a small Ruby script with SQLite's online backup API to write a consistent copy.
- `/hooks/post-restore`: moves that copy back into place before the app boots.

## My takeaways

- If you have an idea that suits a one-time purchase or an internal tool, `rails new` with the default Dockerfile is already close to distributable.
- Read `SECRET_KEY_BASE`, SMTP settings and `NUM_CPUS` from ENV so the same image works for every customer.
- If you use SQLite, add a `pre-backup` hook. Campfire's script is a good example to copy.
- Install ONCE on a spare VPS and try your own image to see what breaks.

Watch the full talk: [Distributing Rails applications with ONCE](https://www.youtube.com/watch?v=eE4aVg15tbs)
