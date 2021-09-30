---
layout: post
title: "Generate a BARCODE for a Product"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails active-storage barcode service-objects
thumbnail: /assets/thumbnails/barcode.png
---

Imagine if you could generate a barcode for each of your products... Well, that's easy!

[The previous post]({% post_url 2021-09-24-qr-code-generation-active-storage-service-objects %})
focused on QR codes.

Final result with both Barcodes and QR for each product:
![barcode and qr in a rails app](/assets/images/barcode-and-qr.png)

**There difference between generating QRcodes and BARcodes is very minor.**

But for Barcodes we will use another gem - [https://github.com/toretore/barby](https://github.com/toretore/barby).

We generated QR codes for the product URL. We will generate Barcodes for the product name.

### Installation

console
```ruby
bundle add barby
bundle add chunky_png
```

app/models/product.rb
```ruby
  has_one_attached :barcode

  after_create :generate_code
  def generate_code
    GenerateBarcode.call(self)
  end
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
class GenerateBarcode < ApplicationService
  attr_reader :product

  def initialize(product)
    @product = product
  end

  require 'barby'
  require 'barby/barcode/code_128'
  require 'barby/outputter/ascii_outputter'
  require 'barby/outputter/png_outputter'

  def call
    barcode = Barby::Code128B.new(product.title)

    # chunky_png required for THIS action
    png = Barby::PngOutputter.new(barcode).to_png

    image_name = SecureRandom.hex

    IO.binwrite("tmp/#{image_name}.png", png.to_s)

    blob = ActiveStorage::Blob.create_after_upload!(
      io: File.open("tmp/#{image_name}.png"),
      filename: image_name,
      content_type: 'png'
    )

    product.barcode.attach(blob)
  end
end
```
