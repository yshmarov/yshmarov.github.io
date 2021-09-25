---
layout: post
title: "Generate a BARCODE for a Product"
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails active-storage barcode
thumbnail: /assets/thumbnails/barcode.png
---

Imagine if you could generate a barcode for each of your products... Well, that's easy!

[The previous post]({% post_url 2021-09-24-2021-09-24-qr-code-generation-active-storage-service-objects %})
focused on QR codes.

**There difference between generating QRcodes and BARcodes is very minor.**

But for Barcodes we will use another gem - [https://github.com/toretore/barby](https://github.com/toretore/barby).

### Installation

console
```
bundle add barby
```

generate a barcode, [source](https://github.com/toretore/barby#example)
```
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/ascii_outputter'

barcode = Barby::Code128B.new('BARBY')
puts barcode.to_ascii
```

save the barcode as an image, [source](https://github.com/toretore/barby/wiki/Outputters)

```
bundle add chunky_png
```

```
require 'barby/outputter/png_outputter'
blob = Barby::PngOutputter.new(barcode).to_png #Raw PNG data
IO.binwrite("tmp/storage/#{SecureRandom.hex}.png", blob.to_s)
```

You can use a ServiceObject to generate barcodes, just as we did in the previous post with PR.
