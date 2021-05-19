---
layout: post
title: Use Rails ActiveStorage with Amazon S3
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails active_storage amazon s3
thumbnail: /assets/thumbnails/pdf.png
---

## 1. Install ActiveStorage. Add attachments locally.

[Official guide](https://edgeguides.rubyonrails.org/active_storage_overview.html)

console:
```
bin/rails active_storage:install
rails db:migrate
```

models/post.rb
```
  has_one_attached :avatar  
```

controller/posts_controller.rb
```
    def post_params
      params.require(:post).permit(:title, :content, :avatar)
    end
```

posts/_form.html.erb
```
  <div class="field">
    <%= form.label :title %>
    <%= form.text_field :title, required: true %>
  </div>
```

posts/show.html.erb
```
<p>
  <strong>Avatar:</strong>
  <% if @post.avatar.attached? %>
    <%= image_tag @post.avatar, width: "200px" %>
    <%= image_tag @post.avatar, width: "100%" %>
  <% end %>
</p>
```

## attach multiple

```
<p>
  <strong>Images:</strong>
  <% if @post.images.attached? %>
    <% @post.images.each do |image| %>
      <%= link_to image.filename, image, target: :blank %>
      <%= image_tag image, width: "200px" %>
    <% end %>
  <% end %>
</p>
```

```
  <div class="field">
    <%= form.label :images %>
    <%= form.file_field :images, multiple: true %>
  </div>
```

## direct upload

    <%= form.file_field :avatar, direct_upload: true %>

##

## purge

## imagemagic

## delete old attachments?

## 2. Configure Amazon S3 cloud storage


create S3 env
create IAM role with S3 access
add

/superails/config/storage.yml
```
amazon:
```


/superails/config/environments/development.rb
```
  config.active_storage.service = :amazon
```



https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/s3-example-bucket-cors.html


[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "HEAD",
            "GET",
            "PUT",
            "POST"
        ],
        "AllowedOrigins": [
            "*"
        ],
        "ExposeHeaders": []
    }
]


amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.aws.dig(Rails.env.to_sym, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.aws.dig(Rails.env.to_sym, :secret_access_key) %>
  region: <%= Rails.application.credentials.aws.dig(Rails.env.to_sym, :region) %>
  bucket: <%= ENV.fetch('AWS_BUCKET') { Settings.aws_bucket } %>



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "S3:*",
            "Resource": [
                "arn:aws:s3:::vas-787937007655-vm-dev-report-bucket/*",
                "arn:aws:s3:::vas-787937007655-vm-dev-report-bucket"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::902086288331:role/pg-dumper"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::vas-787937007655-db-backup-bucket/*"
        }
    ]
}



<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <CORSRule>
        <AllowedOrigin>*</AllowedOrigin>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
    </CORSRule>
</CORSConfiguration>






saas
[
    {
        "AllowedHeaders": [
            "Origin",
            "Content-Type",
            "Content-MD5",
            "Content-Disposition"
        ],
        "AllowedMethods": [
            "PUT"
        ],
        "AllowedOrigins": [
            "https://www.example.com"
        ],
        "ExposeHeaders": [],
        "MaxAgeSeconds": 3600
    }
]

corsego
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET",
            "POST",
            "PUT"
        ],
        "AllowedOrigins": [
            "*"
        ],
        "ExposeHeaders": []
    }
]

DELETE
HEAD