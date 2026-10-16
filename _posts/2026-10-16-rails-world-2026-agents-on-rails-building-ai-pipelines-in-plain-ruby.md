---
layout: post
title: "Rails World 2026: Agents on Rails: Building AI Pipelines in plain Ruby (Daniela Velasquez)"
author: Yaroslav Shmarov
tags: rails-world conference ruby-on-rails ai active-job
thumbnail: /assets/thumbnails/rails-logo.png
youtube_id: OX5coKfra4c
---

Daniela Velasquez from Shopify showed how to build **proactive** AI agents with nothing but Active Job, Active Record and an LLM API. Dashboards and chatbots wait for the user to ask; her pipeline finds insights in your data and brings them to the user. Her running example was a coaching app that studies an athlete's workouts, sleep and heart rate, then suggests next week's training.

## Key ideas

### The researcher is a job

The pipeline starts with a plain `ResearcherJob` for one athlete. Its ingredients:

- **A prompt.** Hers cast the model as a running coach, asked for concrete training changes for next week, and required every change to be backed by data the model actually looked at.
- **An LLM provider** of your choice.
- **Tools** the model may call: workout history, sleep log, plus outside data like a weather forecast and web search. The interesting suggestions often connect your data with the world around the user (heavy rain on Saturday, so move the long run to Sunday).
- **A model and reasoning level.** For research you want a big model with high reasoning, and speed doesn't matter much.

### Surviving deploys

A research run can take 10 to 30 minutes. LLM APIs are stateless, so a deploy that restarts your job workers throws away all the tokens and money spent so far.

The fix: give the job a `Conversation` record. On the first run, save the system prompt and an initial user message asking for research on this athlete. Then loop: send **all stored messages** with the tools to the provider, save every response as a new message, and stop when the model says it's done. If the job restarts, it continues from the stored conversation.

### Judges

LLMs drift. At Shopify, Daniela found the researcher repeatedly telling shops to bundle a Waba shampoo with a Waba conditioner, including a shop that sold bras. The made-up product came from an **example in the prompt**.

Her answer is more LLMs, used as **judges**. Each judge is a narrow classifier that answers a single question: are these numbers real? Is this kind? Can the athlete actually do this (do they own a bike)? Use as many or as few as your app needs.

To trust a judge, measure it:

1. Write about 200 examples that pass and 200 that fail. Telling someone their knees hurt because they never replaced their shoes fails the kindness test.
2. Write a short prompt that asks whether a supportive coach would say this, and wants PASS or FAIL plus a one-sentence reason.
3. Run it over the dataset and check accuracy. Try different prompts and models.

Judges should be **small, fast models with low reasoning**. After the researcher finishes, a second batch of jobs runs every judge on every suggestion, and only suggestions that pass reach the user. In her demo, four suggestions went in and two came out.

### Learning from feedback

Users push back with facts your data doesn't have, like a job that takes up every Sunday morning. Store that and feed it into the next research run. But don't paste raw feedback into the prompt. Angry users produce angry text, and LLMs pick up on patterns. Run it through one more small agent that extracts the fact first:

```ruby
class Feedback < ApplicationRecord
  belongs_to :athlete
  belongs_to :suggestion

  after_create_commit :process_later

  private

  def process_later
    ProcessFeedbackJob.perform_later(self)
  end
end
```

That job asks a cheap model to state, in one sentence, what the coach should remember about this athlete, and saves it as processed text. The researcher prompt then includes those facts. (The class and job names are mine. Daniela showed the model with a callback that enqueues a job.)

The open problem she left us with: facts go stale. The athlete changes jobs and stops working Sundays. Keeping that memory current over time is something everyone building with LLMs will run into.

## My takeaways

- You don't need an agent framework. A job, a messages table and a loop get you a durable agent that survives deploys.
- Check your prompts for examples the model might copy. Daniela's Waba shampoo came from one.
- Before trusting a judge, build a small labeled dataset and measure it, and use cheap models for judging.
- Store user feedback as extracted facts and keep raw text out of the prompt.

Watch the full talk: [Agents on Rails: Building AI Pipelines in plain Ruby](https://www.youtube.com/watch?v=OX5coKfra4c)
