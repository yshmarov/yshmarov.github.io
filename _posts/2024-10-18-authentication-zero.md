---
layout: post
title: Authentication Zero vs Devise
author: Yaroslav Shmarov
tags: hotwire-native
thumbnail: /assets/thumbnails/devise.png
---

Why some people don't like gem Devise:

1. "feels too much like magic"
2. "hard to customize/override defaults"
3. "hard to add 2FA" (2 Factor Authentication)
4. "not session-based" (`User has_many :sessions`)

The Rails 8 authentication generator is supposed to address these particular claims.

The generator adds all the authentication code directly into your app. You will have a bunch of auth code to maintain and be responsible for.

But the Rails 8 auth generator **is currently very limited**.

The generator lacks at least:

- basic test generators
- registrations
- email confirmations

While the authenitcation generator is being actively developed and iterated on, I do not currently recommend it for production use. At least not until `Rails 8.1` is released.

### [lazaronixon/authentication-zero](https://github.com/lazaronixon/authentication-zero)

Authentication-zero is a much more **mature** version of what "Rails 8 authentication generator" strives to be.

It covers all the pitfalls of Devise & Rails 8 Authentication. ***It even has 2FA out of the box!!!***

Even if you are not planning to implement a new authentication solution, I recommend you run the generators on a new Rails app and study the code. It is an elegant learning source!

The default authentication flow in authentication-zero is somewhat different from Devise. For example:

- When a user creates an account, there is a confirmation email sent out straight away. User is `verified:false`.
- There is no built in flow to "re-send confirmation instructions ".
- It is up to the developer to implement flows like "restrict unverified access totally or after X time"

So, if you really want to "own" your authentication, [lazaronixon/authentication-zero](https://github.com/lazaronixon/authentication-zero) is a great starting point! 🚀🚀
