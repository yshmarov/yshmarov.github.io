---
layout: post
title:  Memo on navigation links when using gem devise
author: Yaroslav Shmarov
tags: 
- ruby on rails
- devise
thumbnail: https://2.bp.blogspot.com/-zLeLuzX5ux0/WTUO8RYuiNI/AAAAAAAABAs/eDXmy0SxobYLVmrrQU_jytpYTlaByyrzwCLcB/s400/authentication-crash-course-with-devise.png
---

When installing `gem devise` for a `User` model, add these links to your application:

```
- if current_user
  = link_to current_user.email, user_path(current_user)
  = link_to "Log out", destroy_user_session_path, method: :delete
- else
  = link_to "Log in", new_user_session_path
  = link_to "Register", new_user_registration_path
```
