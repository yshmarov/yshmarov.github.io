---
layout: post
title: "Rails World 2026: Hot Cell: Securing Active Storage in the age of AI (Mike Dalessio)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails active-storage security kamal
thumbnail: /assets/thumbnails/youtube/swXl8M84YmM.jpg
image:
  path: /assets/images/youtube/swXl8M84YmM.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Hot Cell: Securing Active Storage in the age of AI (Mike Dalessio)"
youtube_id: swXl8M84YmM
---

Mike Dalessio (37signals, newest member of the Rails Core team) spent his summer on Rails security issues instead of the Action Text talk he had planned. He told the story of one critical Active Storage CVE and then showed **Hot Cell**, the sandbox 37signals now runs in production so the next image-library zero-day can't reach your secrets. If your app accepts uploads from users, this one is for you.

## Key ideas

### The CVE

[CVE-2026-66066 / GHSA-xr9x-r78c-5hrm](https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm): possible arbitrary file read and remote code execution in Active Storage variant processing. Fixed in **Rails 7.2.3.2, 8.0.5.1 and 8.1.3.1**.

You are affected if you use libvips for variants (`config.active_storage.variant_processor = :vips`, the default since `load_defaults 7.0`) and accept image uploads from untrusted users. That is most Rails apps.

The mechanics, as Mike explained them:

- libvips doesn't decode everything itself. It sniffs the file and routes it to one of many format libraries. Installing libvips on a slim Ruby image pulls in over a hundred of them, including things like libmatio, a MATLAB file reader.
- libvips marks some of these loaders as unsafe for untrusted input, but Active Storage never disabled them.
- A crafted upload could trick a loader into reading arbitrary files, environment variables included, and the generated thumbnail would carry the stolen bytes back out.
- With `secret_key_base` in hand, there are known ways to escalate to remote code execution, plus lateral movement to whatever else your env vars unlock (database, Redis, cloud credentials).

Mike counted **seven small weaknesses** chained together, one being the direct-upload route that existed even in apps that never used direct uploads (Rails main now has `config.active_storage.draw_direct_upload_route` to switch it off). He wrote the advisory as vaguely as he could to buy people time. According to Mike, people reverse-engineered a working exploit from it in under an hour.

Mitigation from the advisory: upgrade Rails, make sure libvips is **>= 8.13** (older versions can't disable the unsafe loaders, and Active Storage will refuse to boot), and **rotate `secret_key_base` and every secret your app process can read**.

### Shrinking the blast radius

New bugs in image libraries keep coming: Mike counted 378 vulnerabilities published this year in libvips and its dependencies. Patching each CVE won't keep up with that, so his goal was to make the next one harmless. His requirements for the sandbox:

- a drop-in replacement: config changes only, no code changes
- least privilege: unprivileged user, dropped capabilities, hard limits on CPU, memory, file size and process count
- no access to the app's filesystem or environment, and **no network interface at all**
- disposable worker processes, deployed with Kamal or Kubernetes like any other container

The name comes from the shielded boxes labs use to handle radioactive material.

### How Hot Cell works

[basecamp/hotcell](https://github.com/basecamp/hotcell) runs as a sibling container. The app talks to it over a **UNIX socket** on a shared volume, and the client passes **open file descriptors** through the socket instead of paths. The cell can read the input and write the output, and it sees nothing else on the app's disk. Inside, a supervisor forks workers, similar to Puma or a job queue.

```ruby
# Gemfile
gem "activestorage-hotcell-client"
```

`bin/rails hotcell:install` creates a `hotcell/` directory with its own Gemfile, Dockerfile, `config.rb` for limits, and an `operations/` folder. Then you swap the Active Storage classes:

```ruby
# config/application.rb
config.active_storage.variant_processor = ActiveStorage::HotCell::Client::Transformers::Image::Vips
config.active_storage.analyzers = [ ActiveStorage::HotCell::Client::Analyzers::Image::Vips ]
config.active_storage.previewers = [ ActiveStorage::HotCell::Client::Previewers::Pdf::Mutool ]
```

Other details from the talk:

- About **8 ms overhead per call** in production at 37signals.
- Custom operations get a `perform` method, modelled on Active Job, so you can sandbox things like unzipping files.
- You can bring your own container image. A conformance test checks that it is locked down properly.
- Observability: Rails instrumentation events, supervisor metrics, and JSON logs explaining why a worker was killed.
- The Active Storage gems need Rails 8.2, which is not released yet.

### Living with AI-found bugs

Mike's response to AI-driven vulnerability discovery: run adversarial review on your own commits, red-team your code with agents, and ship an agent skill with every vulnerability report. For this CVE he published a repo your agent can use to check your Active Storage records for signs of exploitation. He wants us to end up in "Star Trek, not Terminator."

## My takeaways

- **Upgrade Rails today** if you haven't, check your libvips version, and rotate `secret_key_base` plus any secret in your app's environment.
- If you don't use direct uploads, turn off the route once that config option ships in your Rails version.
- Try Hot Cell in staging now so you're ready when Rails 8.2 lands.
- Put agent-driven adversarial review on any code that touches untrusted files.

Watch the full talk: [Hot Cell: Securing Active Storage in the age of AI](https://www.youtube.com/watch?v=swXl8M84YmM)
