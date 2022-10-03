retry on failure
https://discuss.rubyonrails.org/t/implementation-guidance/80579/2
```ruby
module WithRetry
  def with_retry attempts: 2, exception: StandardError
    yield
  rescue exception
    attempts -= 1
    retry if attempts > 1
  end
end
```
```ruby

class MyObject
  include WithRetry

  def some_method
    with_retry do
      something_flaky
    end
  end
end
```