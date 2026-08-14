---
layout: post
title: Ruby AI. Image ALT texts
author: Yaroslav Shmarov
tags: rubyllm neighbour pgvector ai
thumbnail: /assets/static-pages/yaro-avatar.png
---

```ruby
class GenerateAssetAltTextJob < ApplicationJob
  queue_as :default

  def perform(asset_id)
    asset = Asset.find(asset_id)

    return if asset.alt_text.present?
    return if asset.is_video?

    # Check for supported image file types
    return unless asset.file.content_type.start_with?("image/")

    # Check file size limit (20MB)
    return if asset.file.byte_size > 20.megabytes

    begin
      # Create a RubyLLM chat instance
      chat = RubyLLM.chat(model: "gpt-4.1-mini")

      # We need to keep tempfiles alive for the duration of the API call
      @_tempfiles = []

      # Prepare the image file for RubyLLM
      attachment_data = prepare_attachment(asset.file)

      # Create a content object and add the image
      content = RubyLLM::Content.new("Generate a concise and descriptive alt text for this image.")
      content.add_image(attachment_data)

      # Ask RubyLLM to generate alt text
      response = chat.ask(content)&.content

      if response.present?
        # Update the asset with the generated alt text
        asset.update(alt_text: response.strip)
        Rails.logger.info "Successfully generated and saved alt text for Asset ##{asset.id}: #{response.strip}"
      else
        Rails.logger.warn "Failed to generate alt text for Asset ##{asset.id}. Response was empty."
      end
    rescue => e
      Rails.logger.error "An unexpected error occurred while generating alt text for Asset ##{asset.id}: #{e.message}\n#{e.backtrace.join("\n")}"
    ensure
      # Clean up any tempfiles
      @_tempfiles&.each(&:close!)
    end
  end

  private

  def prepare_attachment(attachment)
    if attachment.metadata&.key?("original_url")
      attachment.metadata["original_url"]
    else
      # Create a tempfile for the attachment
      temp_file = Tempfile.new([File.basename(attachment.filename.to_s, ".*"), File.extname(attachment.filename.to_s)])
      temp_file.binmode

      # Resize the image if possible to optimize for vision models
      resized_attachment = attachment.variable? ?
        attachment.variant(resize_to_limit: [650, 1000], saver: {subsample_mode: "on", strip: true, interlace: true, quality: 60}) :
        attachment

      # Download and write the blob data to the tempfile
      temp_file.write(resized_attachment.blob.download)
      temp_file.flush
      temp_file.rewind

      # Store the tempfile reference to prevent GC
      @_tempfiles << temp_file

      # Return the file object itself
      temp_file
    end
  end
end
```
