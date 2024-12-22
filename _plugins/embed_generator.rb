module Jekyll
  class EmbedPage < Page
    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag.html')
      self.data['tag'] = tag
      self.data['title'] = "Posts tagged with \"#{tag}\""
    end
  end

  class EmbedGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'tag'
        dir = 'tags'
        site.tags.keys.each do |tag|
          write_tag_page(site, File.join(dir, tag), tag)
        end
      end
    end

    def write_tag_page(site, dir, tag)
      index = TagPage.new(site, site.source, dir, tag)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end
end