---
layout: post
title: "Rails Raise custom StandardError"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails errors StandardError
thumbnail: /assets/thumbnails/error-sign.png
---

controller.rb
```
        raise(XeroIdError, 'XERO could not provide Invoice ID')
    raise XeroUserRefreshTokenError unless response.success?

  class RecordError < StandardError
    # @param [Dry::Validation::MessageSet] errors
    def initialize(errors)
      @errors = errors

      super("Validation failed for attributes: #{errors.to_h.keys}")
    end

    attr_reader :errors
  end



  # Category not found for EmailMailer exception
  class PostNotPublicError < StandardError
    def message
      'Post is private. You can not view it'
    end
  end

  def action...
    if @post.public?
      redirect_to @post
    else
      raise PostNotPublicError
    end
  end
```

https://blog.appsignal.com/2018/07/03/custom-exceptions-in-ruby.html


        raise "#{valuation.chosen_payee} is not handled"

```
class ImageHandler
  # Domain specific errors
  class ImageExtensionError < StandardError; end
  class ImageTooBigError < StandardError
    def message
      "Image is too big"
    end
  end
  class ImageTooSmallError < StandardError
    def message
      "Image is too small"
    end
  end

  def self.handle_upload(image)
    raise ImageTooBigError if image.size > 10.megabytes
    raise ImageTooSmallError if image.size < 100.kilobytes
    raise ImageExtensionError unless %w[JPG JPEG].include?(image.extension)

    #… do stuff
  end
end
```
