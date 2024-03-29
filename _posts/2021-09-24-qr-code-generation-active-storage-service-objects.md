---
layout: post
title: "Generate a QR code for a Product and store it in ActiveStorage. Service Objects"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails service-objects active-storage qr-code
thumbnail: /assets/thumbnails/qr-superails-com.png
youtube_id: 2AG-JR_zbSU
---

Flow:
1. Generate a QR code based on Product URL
2. Generate a Tempfile PNG file for the QR code
3. Store the PNG file as an ActiveStorage::Blob
4. Attach the ActiveStorage::Blob to the Product
5. Display the attached QR code

Tools:

* [gem rqrcode](https://github.com/whomwah/rqrcode){:target="blank"}
* [ActiveStorage](https://edgeguides.rubyonrails.org/active_storage_overview.html){:target="blank"}
* Url Helpers
* Storage & Temp files
* Service Objects

### STEP 1. Create Products, Install ActiveStorage, Gem Rqrcode

console
```ruby
rails g scaffold Product name
bin/rails active_storage:install
bin/rails db:migrate
bundle add rqrcode
```

### STEP 2. Product has one attached QR, generate QR when Product is created

app/models/product.rb
```ruby
  # store qr code in ActiveStorage
  has_one_attached :qr_code

  after_create :generate_qr
  def generate_qr
    GenerateQrService.new(self).call
  end
```

### STEP 3. ServiceObject - perfect place to store the logic of generating and attaching a QR

console
```ruby
mkdir app/services
echo > app/services/generate_qr.rb
```

app/services/generate_qr_service.rb
```ruby
class GenerateQrService
  attr_reader :product

  def initialize(product)
    @product = product
  end

  # url_for helper
  include Rails.application.routes.url_helpers

  # ensure rqrcode works here
  require "rqrcode"

  def call
    # https://superails.com/products/5?abc=d+e+f
    qr_url = url_for(controller: 'products',
                     action: 'show',
                     id: product.id,
                     host: 'superails.com',
                     only_path: false,
                     abc: 'd e f'
                    )

    # generate QR code
    qr_code = RQRCode::QRCode.new(qr_url)

    # QR code to image  
    qr_png = qr_code.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )

    # name the image
    image_name = SecureRandom.hex

    # attach the generated image object
    product.qr_code.attach(
      io: StringIO.new(qr_png.to_s),
      filename: "#{image_name}.png",
      content_type: "image/png"
    )
  end
end
```

### STEP 4. Display the QR code

app/views/products/_product.html.erb
```ruby
  <%= image_tag(product.qr_code) if product.qr_code.attached? %>
```

****

### OTHER THOUGHTS & NOTES

Previously, before using `StringIO`, I would save the file locally, upload it to storage, and later attach it:

```ruby
# save the image in TMP
image = IO.binwrite("tmp/storage/#{image_name}.png", qr_png.to_s)

# save TMP file to ActiveStorage
# blob = ActiveStorage::Blob.create_after_upload!(
blob = ActiveStorage::Blob.create_and_upload!(
  io: File.open("tmp/storage/#{image_name}.png"),
  filename: image_name,
  content_type: 'png'
)

# attach ActiveStorage::Blob to the product
product.qr_code.attach(blob)
```

What if we write not to `tmp/storage/..`, but to Tempfile?


```ruby
file = Tempfile.new(['hello', '.jpg'])
file.path  # => something like: "/tmp/foo2843-8392-92849382--0.jpg"

product.qr_code.attach(io: File.open("/path/to/face.jpg"), filename: "face.jpg", content_type: "image/jpg")

blob = ActiveStorage::Blob.create_after_upload!(
  io: File.open("tmp/storage/04755c23b32185f09bb1a20aabcc823c.png"),
  filename: '04755c23b32185f09bb1a20aabcc823c',
  content_type: 'png'
)

ActiveStorage::Blob.first
```