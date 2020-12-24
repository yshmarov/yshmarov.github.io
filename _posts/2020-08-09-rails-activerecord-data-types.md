---
layout: post
title:  Memo - Rails ActiveRecord data types
author: Yaroslav Shmarov
tags: 
- ruby on rails
thumbnail: https://pbs.twimg.com/media/CZGHPChUAAA3jqE.png
---

The common ActiveRecord data types available in Rails 6.

```
:string - short text
:text - long text
:integer - whole numbers [-1, 0, 1, 445]
:bigint - large whole numbers [345654765]
:float - double-precision floating-point numbers [5645,24]
:decimal - high-prescision floating-point numbres [5645,2342343241212]
:datetime
:time
:date
:boolean - true or false
```

These data types are used in instances such as migrations.

```
def change
  create_table :categories do |t|
    t.string :title
    t.text :content
    t.boolean :publised
  end
end
```