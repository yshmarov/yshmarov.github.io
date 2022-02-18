---
layout: post
title: Complete guide to generating PDFs with gem wicked_pdf
author: Yaroslav Shmarov
tags: ruby rails ruby-on-rails pdf wicked_pdf
thumbnail: /assets/thumbnails/pdf.png
---

[wicked_pdf](https://github.com/mileszs/wicked_pdf) - gem to generate PDF from HTML.

It is based on `wkhtmltopdf` technology.

By the end of the post we will be able to:
1. Generate PDF from posts/index.html.erb
2. Style your PDFs
3. Customize your PDF generations
4. Generate PDF from posts/show.html.erb
5. Email a PDF as an attachment
6. It will work on heroku!

### Level 1. Basic installation

Gemfile

```ruby
gem 'wicked_pdf'
gem "wkhtmltopdf-binary", group: :development
gem "wkhtmltopdf-heroku", group: :production
```

console

```
bundle
rails g wicked_pdf
echo > app/assets/stylesheets/pdf.scss
```

Now you can test the installation by running something like `wkhtmltopdf http://google.com google.pdf` to generate a pdf from this URL

(If it is set up this way, it will work correctly on heroku) config/initializers/wicked_pdf.rb

```ruby
WickedPdf.config ||= {}
WickedPdf.config.merge!({
  layout: "pdf.html.erb",
}) 
```

config/initializers/mime_types.rb

```ruby
Mime::Type.register "application/pdf", :pdf
```

app/views/layouts/pdf.html.erb

```ruby
<!DOCTYPE html>
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <%= wicked_pdf_stylesheet_link_tag "pdf" %>
    <%= wicked_pdf_javascript_include_tag "number_pages" %>
  </head>
  <body onload="number_pages">
    <div id="header">
      <!--= wicked_pdf_image_tag 'thumbnail.png', height: "30", width: "auto"-->
    </div>
    <div id="content">
      <%= yield %>
    </div>
  </body>
</html>
```

app/controllers/posts_controller.rb

```ruby
  def index
    @posts = Post.all
    respond_to do |format|
      format.html
      format.pdf do
        render template: "posts/index.html.erb",
          pdf: "Posts: #{@posts.count}"
      end
    end
  end
```

app/views/posts/index.html.erb

```ruby
<%= link_to "PDF", posts_path(format: :pdf) %>
```

## Level 2. Style your PDFs

app/assets/stylesheets/pdf.scss

```
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
} 
table {
  width: 100%;
}
```

You might want to REMOVE this line from application.scss
```
 *= require_tree .
```

## Level 3. Customize your PDF generations

config/initializers/wicked_pdf.rb
```ruby
WickedPdf.config ||= {}
WickedPdf.config.merge!({
  layout: "pdf.html.erb",
  orientation: "Landscape", # Portrait
  page_size: "A4",
  lowquality: true,
  zoom: 1,
  dpi: 75
})
```

[all options](https://github.com/mileszs/wicked_pdf#advanced-usage-with-all-available-options)

`disposition: 'attachment'` - by default download PDF
`disposition: 'inline'` - by default open PDF in browser

## Level 4. Generate PDF from posts/show.html.erb

app/controllers/posts_controller.rb
```ruby
  def show
    respond_to do |format|
      format.html
      format.pdf do
        render template: "posts/show.html.erb",
          pdf: "Post ID: #{@post.id}"
      end
    end
  end
```

app/views/posts/index.html.erb
```ruby
<%= link_to 'This post in PDF', post_path(post, format: :pdf) %>
```

You can also have a separate template for PDF-only like `render template: "pdfs/payment_received.html.erb"`

## Level 5. Email a PDF as an attachment

console

```
rails g mailer PostMailer new_post
```

action to trigger the mailer (in any controller, for example posts#show)
```ruby
PostMailer.new_post.deliver_later
```

app/mailers/post_mailer.rb
```ruby
  # def pdf_attachment_method(post_id)
  def new_post
    # post = Post.find(post_id)
    # @post = Post.first
    post = Post.first
    attachments["post_#{post.id}.pdf"] = WickedPdf.new.pdf_from_string(
      render_to_string(template: 'posts/show.html.erb', layout: 'pdf.html.erb', pdf: 'filename')
    )
    mail to: "to@example.org"
  end
end
```

& now if you navigate to the email preview path `rails/mailers/post_mailer/new_post`, you will see an attachment!

## That's it!

****

Part 2 of this post would potentially be wicked_pdf + AWS S3:
* save the PDF on AWS S3
* current post to have a relation to this PDF on AWS S3
* button to download the PDF from AWS S3
