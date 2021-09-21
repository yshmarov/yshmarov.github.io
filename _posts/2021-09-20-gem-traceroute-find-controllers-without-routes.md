---
layout: post
title: "Gem Traceroutes - find routes without controller actions, actions without routes"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails code-quality
thumbnail: /assets/thumbnails/rubocop.png
---

[gem traceroute](https://github.com/amatsuda/traceroute) is a simple gem to:
* Find controllers without linked routes
* Find routes without linked controller actions

### Install

console

```
bundle add traceroute
```

### Execute

```
rake traceroute
```

### Ignore routes or controller actions

console

```
echo > .traceroute.yaml
```

.traceroute.yaml

```
ignore_unused_routes:
  - ^rails/conductor/action_mailbox/inbound_emails#edit
  - ^rails/conductor/action_mailbox/inbound_emails#update
  - ^rails/conductor/action_mailbox/inbound_emails#update
  - ^rails/conductor/action_mailbox/inbound_emails#destroy
ignore_unreachable_actions:
  - ^devise\/
  - ^devise_invitable\/
```
