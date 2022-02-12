---
layout: post
title: 'Ruby on Rails 6: Subdomain validation'
date: '2020-10-11T15:53:00.001+02:00'
author: yaro_the_slav
tags: 
modified_time: '2020-10-11T15:53:53.410+02:00'
blogger_id: tag:blogger.com,1999:blog-5936476238571675194.post-8286073199710732869
---

validates :subdomain, 

	exclusion: {in: RESERVED_SUBDOMAINS, message: "%{value} is reserved."}, 

	format: {with: /\A[a-zA-Z0-9]+[a-zA-Z0-9\-_]*[a-zA-Z0-9]+\Z/, 

	message: "must be at least 2 characters and alphanumeric", 

	allow_blank: true}

RESERVED_SUBDOMAINS = %w[app help support]

#validates :subdomain, presence: true, uniqueness: true, case_sensitive: false,

  #  length: { in: 2..30 }, 

  #  format: {with: %r{\A[a-z](?:[a-z0-9-]*[a-z0-9])?\z}i, message: "not a valid subdomain"},

  #  exclusion: { in: %w(app apps dashboard support blog billing help api www host admin), message: "%{value} is reserved." }
