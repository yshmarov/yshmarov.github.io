

```ruby
get insta_user_posts_url(@insta_user, format: :turbo_stream)
assert_match 'Post by this user', response.body
assert_no_match 'Post by other user', response.body

post import_insta_user_path(@insta_user, format: :turbo_stream)
assert_response :success
assert_match 'Posts are being imported. This can take a few minutes', @response.body
```
