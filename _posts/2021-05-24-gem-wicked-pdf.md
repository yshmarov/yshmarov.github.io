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

```shell
# terminal
bundle
rails g wicked_pdf
echo > app/assets/stylesheets/pdf.scss
```

Now you can test the installation by running something like `wkhtmltopdf http://google.com google.pdf` to generate a pdf from this URL

To make the initializer work correctly on Heroku:

```ruby
# config/initializers/wicked_pdf.rb
WickedPdf.config ||= {}
WickedPdf.config.merge!({
  layout: "pdf.html.erb",
}) 
```

Optionally you might need to add a mime type:

```ruby
# config/initializers/mime_types.rb
Mime::Type.register "application/pdf", :pdf
```

Create a separate HTML layout file for generating your PDFs:

```ruby
# app/views/layouts/pdf.html.erb
<!DOCTYPE html>
<html>
  <head>
    <title>Appname</title>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= wicked_pdf_stylesheet_link_tag "pdf" %>
  </head>
  <body>
    <div id="header">
      <!--= wicked_pdf_image_tag 'thumbnail.png', height: "30", width: "auto"-->
    </div>
    <%= yield %>
  </body>
</html>
```

```ruby
# app/controllers/posts_controller.rb
  def index
    @posts = Post.all
    respond_to do |format|
      format.html
      format.pdf do
        # Rails 6
        # render template: "posts/index.html.erb",
        #        pdf: "Posts: #{@posts.count}"

        # Rails 7
        # https://github.com/mileszs/wicked_pdf/issues/1005
        render pdf: "Posts: #{@posts.count}", # filename
               template: "hello/print_pdf",
               formats: [:html],
               disposition: :inline,
               layout: 'pdf'
      end
    end
  end
```

```ruby
# app/views/posts/index.html.erb
<%= link_to "PDF", posts_path(format: :pdf) %>
```

## Level 2. Style your PDFs

```css
/* app/assets/stylesheets/pdf.css */
body {
  background-color: green;
}
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
} 
table {
  width: 100%;
}
```

You might want to REMOVE this line from application.css, so that `pdf.css` is not available anywhere else around the app:

```diff
- *= require_tree .
```

## Level 3. Customize your PDF generations

```ruby
# config/initializers/wicked_pdf.rb
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

```ruby
# app/controllers/posts_controller.rb
  def show
    respond_to do |format|
      format.html
      format.pdf do
        # Rails 6:
        # render template: "posts/show.html.erb",
        #        pdf: "Post ID: #{@post.id}"

        # Rails 7:
        render pdf: [@post.id, @post.name].join('-'),
               template: "posts/show.html.erb",
               formats: [:html],
               disposition: :inline,
               layout: 'pdf'
      end
    end
  end
```

```ruby
# app/views/posts/index.html.erb
<%= link_to 'This post in PDF', post_path(post, format: :pdf) %>
```

You can also have a separate template for PDF-only like `render template: "pdfs/payment_received.html.erb"`

## Level 5. Email a PDF as an attachment


```shell
# terminal
rails g mailer PostMailer new_post
```

action to trigger the mailer (in any controller, for example posts#show):

```ruby
PostMailer.new_post.deliver_later
```

```ruby
# app/mailers/post_mailer.rb
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
