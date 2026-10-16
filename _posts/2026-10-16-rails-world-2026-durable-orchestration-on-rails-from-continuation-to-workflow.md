---
layout: post
title: "Rails World 2026: Durable orchestration on Rails: from continuation to workflow (Vladimir Dementyev)"
author: Yaroslav Shmarov
tags: rails-world conference active-job background-jobs solid-queue
thumbnail: /assets/thumbnails/youtube/4dcv1a7eeMk.jpg
image:
  path: /assets/images/youtube/4dcv1a7eeMk.jpg
  width: 1280
  height: 720
  alt: "Rails World 2026: Durable orchestration on Rails: from continuation to workflow (Vladimir Dementyev)"
youtube_id: 4dcv1a7eeMk
---

Vladimir Dementyev (Evil Martians) argued that Active Job **continuations**, added to survive deploys mid-job, have quietly become an orchestration primitive. The talk walks through the multi-job patterns every big Rails app grows and introduces a gem that makes continuations durable.

## Key ideas

### From workaround to primitive

Continuations (`include ActiveJob::Continuable`, `step`, cursors) let a long job stop and resume from a checkpoint. The original motivation was deploys: without them, a restarted job replays from the start and might send the same webhook twice. The usual workaround was fanning out one job per record.

A year later, people use steps to organize multi-step work in a single file: split a long LLM job into isolated steps, replace a chain of jobs that enqueue each other. Half of the interesting open Active Job PRs are continuation-related, many from the community.

But it's still too primitive. The state lives only in the job payload, so you can't see which step a job is on. There are no step callbacks, no per-step error handling, and no uniqueness.

### The patterns

- **Pipelines**: job A enqueues job B on success, which enqueues C... A month later nobody knows where the chain starts or how it fails.
- **Batches**: fan out, then run something on completion. Usually needs counters or polling. **Solid Queue 1.7** now ships batches (contributed by JP Camara). GoodJob and Doximity's **simplekiq** have their own takes.
- **Timers**: reminders and expirations built from recurring sweeps, or jobs parked with `wait_until` that you can't cancel, so you re-check relevance when they run.
- **Signals / human-in-the-loop**: one process split in the middle by a user action or a webhook, spread across several files.

Existing tools: **acidic_job** (durable, keeps the Active Job interface), **geneva_drive** (great features, but its own DSL), **chrono_forge**, and services like Temporal. Vladimir showed a real withdrawal flow done with Temporal and wasn't impressed by how much code it took.

### AJ/DC: Active Job Durable Continuation

Vladimir's answer is the **ajdc** gem: the job's run and steps are stored as database records in addition to the queue payload. It is designed as an extension of Active Job that could one day be merged into Rails. Migration is one line:

```ruby
class ImportJob < ApplicationJob
  include ActiveJob::Durable # instead of ActiveJob::Continuable
  unique_by :import
  halt_on InsufficientStorageSpaceError
  after_step :broadcast_progress

  def perform(import)
    step :validate
    step :process do |step|
      import.records.find_each(start: step.cursor) do |record|
        record.process!
        step.advance! from: record.id
      end
    end
  end
end
```

What you get:

- **Durable state**: runs and steps (status, cursor, attributes) are Active Record models you can query, e.g. `ImportJob.workflow_runs.failed.at_step(:process)`. Cursors survive a hard crash as well as a graceful stop.
- **Step callbacks**: `before_step`, `after_step`, `around_step`.
- **Halting**: `halt_on` / `halt!` pause a run on a recoverable error so you can `resume!` it later. `discard_on` throws it away instead.
- **Uniqueness**: `unique_by`, with `on_conflict: :replace` to restart a workflow, e.g. after a license renewal.
- **Timers**: `step :remind, wait_until: license.expires_at - 2.weeks` puts the run to sleep. A recurring `WakeJob` wakes due runs.
- **Signals**: `await :confirmation, wait: 10.minutes` parks the run until a controller calls `wake_up(:confirmation, true)`.

The gem also ships an agent skill, so you can ask your coding agent to find jobs worth migrating.

## My takeaways

- If you still use Sidekiq workers directly, consider moving to Active Job. It now adds features of its own.
- Look for job chains, polling coordinators and webhook-split flows in your app. They are good candidates for one job with steps.
- Need batches and already on Solid Queue? Upgrade to 1.7 before reaching for another gem.
- Try `ajdc` on one workflow where you currently keep step state in model columns.

Watch the full talk: [Durable orchestration on Rails: from continuation to workflow](https://www.youtube.com/watch?v=4dcv1a7eeMk)
