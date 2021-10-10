---
layout: post
title: "Basic set-up for Service Objects and examples"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails service-objects
thumbnail: /assets/thumbnails/process.png
---

Use ServiceObjects to abstract reusable business logic from models and controllers.

### 1. Basic setup

console
```sh
rails g scaffold Product name barcode vendor_code
```

console
```sh
mkdir app/services
touch app/services/generate_barcode.rb
```

app/services/generate_barcode.rb
```ruby
class GenerateBarcode

  DEFAULT_BARCODE = 3_000_000_200_000
  DEFAULT_VENDOR_CODE = 13_000

  def initialize(product)
    @product = product
  end

  def add_barcode
  	@product.update!(barcode: DEFAULT_BARCODE + @product.id)
  end

  def add_vendor_code
  	@product.update!(vendor_code: DEFAULT_VENDOR_CODE + @product.id)
  end
end
```

app/controllers/products_controller.rb
```ruby
def create
    @product = Product.new(product_params)
    if @product.save
      GenerateBarcode.new(@product).add_barcode
      GenerateBarcode.new(@product).add_vendor_code
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end
```

### 2. Single-responsibility principle. `Call`

console
```sh
touch app/services/application_service.rb
```

app/services/application_service.rb
```ruby
class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end
end
```

app/services/generate_barcode.rb
```ruby
class GenerateBarcodeService

  DEFAULT_BARCODE = 3_000_000_200_000
  DEFAULT_VENDOR_CODE = 13_000

  def initialize(product)
    @product = product
  end

  def call
  	add_barcode
  	add_vendor_code
  end

  private

  def add_barcode
  	@product.update!(barcode: DEFAULT_BARCODE + @product.id)
  end

  def add_vendor_code
  	@product.update!(vendor_code: DEFAULT_VENDOR_CODE + @product.id)
  end
end
```

app/controllers/products_controller.rb
```ruby
def create
    @product = Product.new(product_params)
    if @product.save
      GenerateBarcode.call(@product)
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end
```

### 3. 

# app/services/book_creator.rb
```ruby
class BookCreator < ApplicationService
  def initialize(title:, description:, author_id:, genre_id:)
    @title = title
    @description = description
    @author_id = author_id
    @genre_id = genre_id
  end

  def call
    create_book
  end

  private

  def create_book
    subscription = Stripe::Subscription.create(@subscription_params)
  rescue Stripe::StripeError => e
    OpenStruct.new({success?: false, error: e})
  else
    OpenStruct.new({success?: true, payload: subscription})
  end
end
```
controller
```ruby
class BookController < ApplicationController
  def create
    BookCreator.call(
    title: params[:title],
    description: params[:description],
    author_id: params[:author_id],
    genre_id: params[:genre_id])
  end
end
```

### 4. Rescue

```ruby
	def call
	   begin
	   rescue Stripe ::StripeError  => e
	   else
	   end
	end
```

### 5. Nest


services
├── application_service.rb
└── product
├── product_creator.rb
└── product_reader.rb

# services/product/product_creator.rb
module Product
  class ProductCreator < ApplicationService
  ...
  end
end

# services/twitter_manager/book_reader.rb
module Book
  class BookReader < ApplicationService
  ...
  end
end
