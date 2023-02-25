---
layout: post
title: "Reverse Engineering Pipplet Database Architecture"
author: Yaroslav Shmarov
tags: database architecture
thumbnail: /assets/thumbnails/pipplet-logo.png
---

🔍 Recently [Pipplet](https://www.pipplet.com/){:target="blank"} app has come to my spotlight.

It is an online language testing platform, used by businesses to evaluate an individuals skills.

As a pleasant surprise, the platform does not offer multiple-choice questions.

Instead, it has open-ended questions.

That way candidates are less likely to be able to cheat!

👨‍💻 In this session I am planning to navigate their UI and map-out how I would reproduce their apps functionality.

⚠️ I am in no way affiliated with Pipplet. I **do not endorse** their platform either.

Youtube video: [**Reverse Engineering a Web App: Pipplet Language Testing Platform**](https://youtu.be/yYt-SlVt-yY){:target="blank"}

## Important interfaces within the Pipplet app:

Target audience (customers) on registration:

![pipplet-account-types](/assets/images/pipplet-account-types.png)

Onboarding flow

![pipplet-onboarding-flow](/assets/images/pipplet-onboarding-flow.png)

Buy credits. Taking the test by each individual costs around $40.

![pipplet-buy-credits](/assets/images/pipplet-buy-credits.png)

Create campaign with a subject (language), that will have a group of test takers:

![pipplet-create-campaign](/assets/images/pipplet-create-campaign.png)

Add test takers that will invited to take the test.

![pipplet-add-test-takers](/assets/images/pipplet-add-test-takers-to-campaign.png)

Company dashboard with all test takers and campaigns

![pipplet-dashboard.png](/assets/images/pipplet-dashboard.png)

Question with audio answer

![pipplet-audio-question-example.jpg](/assets/images/pipplet-audio-question-example.jpg)

Question with text answer

![pipplet-open-question-example.png](/assets/images/pipplet-open-question-example.png)

Language Certificate example

![pipplet-certificate-example.png](/assets/images/pipplet-certificate-example.png)

## Analysis

4 types of users and interfaces:
1. Company team accounts - they buy credits, create campaigns, request test takers.
2. Evaluators/Examiners - they create Questions within Subjects and score answers (2 different interfaces)
3. Candidates/Test takers - they answer questions.
4. Superadmin - moderate evaluators.

## Database architecture

Link to the [Database Diagram](https://dbdiagram.io/d/63fa64e8296d97641d83b984){:target="blank"} that I created:

![pipplet-dbml.png](/assets/images/pipplet-dbml.png)

The tables with core associations and attirbutes, in [DBML format](https://www.dbml.org/home/#intro){:target="blank"}:

```t
Table users {
  id int [pk]
  email string
}

Table organization_users {
  id int [pk]
  user_id int [ref: > users.id]
  organization_id int [ref: > organization.id]
}

Table organization {
  id int [pk]
  credits int
}

Table campaign {
  id int [pk]
  name str
  organization_id int [ref: > organization.id]
  subject_id int [ref: > subject.id]
}

Table subject {
  id int [pk]
  name str
}

Table question {
  id int [pk]
  subject_id int [ref: > subject.id]
  examiner_id int [ref: > examiner.id]
  type str // reading/image_description_audio/dialogue_answer/image_description_text
  instruction_text text
  body text
  max_characters int
  // active storage image attachment
  // active storage audio attachment
}

Table answer {
  id int [pk]
  test_taker_id int [ref: > test_taker.id]
  examiner_id int [ref: > examiner.id]
  question_id int [ref: > question.id]
  // active storage audio attachment
  body text
  answered boolean // !skipped
  score integer
  score_description text
}

Table test_taker {
  id int [pk]
  email str
  campaign_id int [ref: > campaign.id]
  status string // not_started/evaluation_pending/evaluated
  score integer
  score_description text
}

Table examiner {
  id int [pk]
  email str

}
```

## Most challenging features to build (imho):
- Audio recording (JS, ActiveStorage)
- Audio analysis toolkit
- TestTaker onboarding flow (maybe just use a js plugin)

That's it!
