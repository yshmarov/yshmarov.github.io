
https://www.bigbinary.com/blog/rails-6-1-adds-invert_where


```
  scope :all_except, ->(user) { where.not(id: user) }
  scope :public_rooms, -> { where(is_private: false) }
```
