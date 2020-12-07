---
layout: post
title:  "How to Embed Youtube videos with ActionText? TLDR"
author: Yaroslav Shmarov
tags: 
- ruby-on-rails
- actiontext
- youtube
- embed
- tldr
thumbnail: https://i.pinimg.com/originals/0e/0a/1b/0e0a1ba222b86afd23b1a8a5b3530f30.png
---

# Final result:
![embed youtube actiontext](/assets/2020-11-16-action-text-embed-youtube/embed youtube actiontext.gif)

[Original Youtube video where it is introduced by Chris Oliver](https://www.youtube.com/watch?v=2iGBuLQ3S0c){:target="blank"}

app/views/youtubes/_thumbnail.html.erb
{% highlight ruby %}
<div>
  <%= image_tag youtube.thumbnail_url, style: "max-width:400px" %>
</div>
{% endhighlight %} 

app/views/youtubes/_youtube.html.erb
{% highlight ruby %}
<div>
  <iframe id="ytplayer" type="text/html" width="640" height="360" src="https://www.youtube.com/embed/<%= youtube.id %>" frameborder="0"></iframe>
</div>
{% endhighlight %} 

packs/application.js
{% highlight ruby %}
import "youtube"
{% endhighlight %} 


application.rb 
{% highlight ruby %}
    config.to_prepare do
      ActionText::ContentHelper.allowed_tags << "iframe"
    end
{% endhighlight %} 

routes.rb
{% highlight ruby %}
  resources :youtube, only: :show
{% endhighlight %} 

models/youtube.rb
{% highlight ruby %}
class Youtube
  include ActiveModel::Model
  include ActiveModel::Attributes
  include GlobalID::Identification
  include ActionText::Attachable

  attribute :id

  def self.find(id)
    new(id: id)
  end

  def thumbnail_url
    "http://i3.ytimg.com/vi/#{id}/maxresdefault.jpg"
  end

  def to_trix_content_attachment_partial_path
    "youtubes/thumbnail"
  end
end
{% endhighlight %} 

controllers/youtube_controller.rb
{% highlight ruby %}
class YoutubeController < ApplicationController
  def show
    @youtube = Youtube.new(id: params[:id])
    render json: {
      sgid: @youtube.attachable_sgid,
      content: render_to_string(partial: "youtubes/thumbnail", locals: { youtube: @youtube }, formats: [:html])
    }
  end
end
{% endhighlight %} 
  
javascript/youtube.js
{% highlight ruby %}
import Trix from "trix"
import Rails from "@rails/ujs"

let lang = Trix.config.lang;
Trix.config.toolbar = {
  getDefaultHTML: function() {
    return `
    <div class="trix-button-row">
      <span class="trix-button-group trix-button-group--text-tools" data-trix-button-group="text-tools">
        <button type="button" class="trix-button trix-button--icon trix-button--icon-bold" data-trix-attribute="bold" data-trix-key="b" title="${lang.bold}" tabindex="-1">${lang.bold}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-italic" data-trix-attribute="italic" data-trix-key="i" title="${lang.italic}" tabindex="-1">${lang.italic}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-strike" data-trix-attribute="strike" title="${lang.strike}" tabindex="-1">${lang.strike}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-link" data-trix-attribute="href" data-trix-action="link" data-trix-key="k" title="${lang.link}" tabindex="-1">${lang.link}</button>
      </span>
      <span class="trix-button-group trix-button-group--block-tools" data-trix-button-group="block-tools">
        <button type="button" class="trix-button trix-button--icon trix-button--icon-heading-1" data-trix-attribute="heading1" title="${lang.heading1}" tabindex="-1">${lang.heading1}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-quote" data-trix-attribute="quote" title="${lang.quote}" tabindex="-1">${lang.quote}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-code" data-trix-attribute="code" title="${lang.code}" tabindex="-1">${lang.code}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-bullet-list" data-trix-attribute="bullet" title="${lang.bullets}" tabindex="-1">${lang.bullets}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-number-list" data-trix-attribute="number" title="${lang.numbers}" tabindex="-1">${lang.numbers}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-decrease-nesting-level" data-trix-action="decreaseNestingLevel" title="${lang.outdent}" tabindex="-1">${lang.outdent}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-increase-nesting-level" data-trix-action="increaseNestingLevel" title="${lang.indent}" tabindex="-1">${lang.indent}</button>
      </span>
      <span class="trix-button-group trix-button-group--file-tools" data-trix-button-group="file-tools">
        <button type="button" class="trix-button trix-button--icon trix-button--icon-attach" data-trix-action="attachFiles" title="${lang.attachFiles}" tabindex="-1">${lang.attachFiles}</button>
      </span>
      <span class="trix-button-group-spacer"></span>
      <span class="trix-button-group trix-button-group--history-tools" data-trix-button-group="history-tools">
        <button type="button" class="trix-button trix-button--icon trix-button--icon-undo" data-trix-action="undo" data-trix-key="z" title="${lang.undo}" tabindex="-1">${lang.undo}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-redo" data-trix-action="redo" data-trix-key="shift+z" title="${lang.redo}" tabindex="-1">${lang.redo}</button>
      </span>
    </div>
    <div class="trix-dialogs" data-trix-dialogs>
      <div class="trix-dialog trix-dialog--link" data-trix-dialog="href" data-trix-dialog-attribute="href">
        <div class="trix-dialog__link-fields">
          <input type="url" name="href" class="trix-input trix-input--dialog" placeholder="${lang.urlPlaceholder}" aria-label="${lang.url}" required data-trix-input>
          <div class="flex">
            <input type="button" class="btn btn-secondary btn-small mr-1" value="${lang.link}" data-trix-method="setAttribute">
            <input type="button" class="btn btn-tertiary outline btn-small" value="${lang.unlink}" data-trix-method="removeAttribute">
          </div>
        </div>
        <div data-behavior="embed_container">
          <div class="link_to_embed link_to_embed--new">
            Would you like to embed media from this site?
            <input class="btn btn-tertiary outline btn-small ml-3" type="button" data-behavior="embed_url" value="Yes, embed it">
          </div>
        </div>
      </div>
    </div>
  `
  }
}

class EmbedController {
  constructor(element) {
    this.pattern = /^https:\/\/([^\.]+\.)?youtube\.com\/watch\?v=(.*)/

    this.element = element
    this.editor = element.editor
    this.toolbar = element.toolbarElement
    this.hrefElement = this.toolbar.querySelector("[data-trix-input][name='href']")
    this.embedContainerElement = this.toolbar.querySelector("[data-behavior='embed_container']")
    this.embedElement = this.toolbar.querySelector("[data-behavior='embed_url']")

    this.reset()
    this.installEventHandlers()
  }

  installEventHandlers() {
    this.hrefElement.addEventListener("input", this.didInput.bind(this))
    this.hrefElement.addEventListener("focusin", this.didInput.bind(this))
    this.embedElement.addEventListener("click", this.embed.bind(this))
  }

  didInput(event) {
    let value = event.target.value.trim()
    let matches = value.match(this.pattern)
    console.log(value,matches)

    // When patterns are loaded, we can just fetch the embed code
    if (matches != null) {
      this.fetch(matches[2])

    // No embed code, just reset the form
    } else {
      this.reset()
    }
  }

  fetch(value) {
    Rails.ajax({
      url: `/youtube/${encodeURIComponent(value)}`,
      type: 'get',
      error: this.reset.bind(this),
      success: this.showEmbed.bind(this)
    })
  }

  embed(event) {
    if (this.currentEmbed == null) { return }

    let attachment = new Trix.Attachment(this.currentEmbed)
    this.editor.insertAttachment(attachment)
    this.element.focus()
  }

  showEmbed(embed) {
    this.currentEmbed = embed
    this.embedContainerElement.style.display = "block"
  }

  reset() {
    this.embedContainerElement.style.display = "none"
    this.currentEmbed = null
  }
}

document.addEventListener("trix-initialize", function(event) {
  new EmbedController(event.target)
})
{% endhighlight %} 

* [gist with this solution](https://gist.github.com/yshmarov/90377ba51f14df09df03e6442cd7412e){:target="blank"}
* [this question on Stackoverflow](https://stackoverflow.com/questions/61867995/how-to-embed-an-iframe-with-actiontext-trix-on-ruby-on-rails/62407131?noredirect=1#comment114555980_62407131){:target="blank"}