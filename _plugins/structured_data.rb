# frozen_string_literal: true

require "json"

# One JSON-LD @graph per page, built in Ruby so it is always valid JSON.
#
# Every page carries the same Person (#person) and WebSite (#website) nodes and
# then describes itself in terms of them: the homepage is a ProfilePage about
# the Person, a post is a BlogPosting whose author is the Person (or its guest
# author), and so on. Search engines and LLM crawlers resolve the @id
# references into a single entity instead of a dozen loosely matching names.
#
# jekyll-seo-tag also emits a JSON-LD block, with no option to turn it off. It
# contradicted ours (the homepage had two WebSite entities, /about/ was typed
# as a WebSite, posts had two BlogPostings), so the hook at the bottom drops it.
# The rest of jekyll-seo-tag's output (title, canonical, OpenGraph, Twitter) is
# kept.
#
# Usage: {% structured_data %} in the <head>. Asserted by `rake smoke`.
module StructuredData
  class << self
    def graph(site, page)
      base = site.config["url"].to_s
      profile = site.data["profile"] || {}
      nodes = [person(site, profile, base), website(site, base)]
      nodes.concat(page_nodes(site, page, profile, base))
      { "@context" => "https://schema.org", "@graph" => nodes }
    end

    private

    def person_id(base) = "#{base}/#person"
    def website_id(base) = "#{base}/#website"
    def blog_id(base) = "#{base}/blog/#blog"
    def ref(id) = { "@id" => id }
    def abs(base, path) = path.to_s.start_with?("http") ? path.to_s : "#{base}#{path}"

    def person(site, p, base)
      employer = Array(p["work"]).find { |w| w["employer"] }
      node = {
        "@type" => "Person",
        "@id" => person_id(base),
        "name" => p["name"] || site.config.dig("author", "name"),
        "alternateName" => p["short_name"],
        "url" => "#{base}/",
        "image" => abs(base, p["photo"]),
        "description" => site.config["description"].to_s.strip,
        "email" => p["email"] && "mailto:#{p["email"]}",
        "homeLocation" => p["home_location"] && { "@type" => "Place", "name" => p["home_location"] },
        "knowsLanguage" => p["languages"],
        "knowsAbout" => p["knows_about"],
        "worksFor" => employer && { "@type" => "Organization", "name" => employer["org"], "url" => employer["url"] },
        "sameAs" => (Array(site.config.dig("social", "links")) + [p["talks_profile"]]).compact.uniq,
      }
      compact(node)
    end

    def website(site, base)
      {
        "@type" => "WebSite",
        "@id" => website_id(base),
        "url" => "#{base}/",
        "name" => site.config["title"],
        "description" => site.config["description"].to_s.strip,
        "inLanguage" => site.config["lang"] || "en",
        "publisher" => ref(person_id(base)),
        "potentialAction" => {
          "@type" => "SearchAction",
          "target" => { "@type" => "EntryPoint", "urlTemplate" => "#{base}/blog/?q={search_term_string}" },
          "query-input" => "required name=search_term_string",
        },
      }
    end

    def page_nodes(site, page, profile, base)
      url = abs(base, page["url"])
      common = {
        "@id" => "#{url}#webpage",
        "url" => url,
        "name" => page["title"] || site.config["title"],
        "description" => page["description"],
        "inLanguage" => site.config["lang"] || "en",
        "isPartOf" => ref(website_id(base)),
      }

      case
      when page["layout"] == "post"
        posting(site, page, base, url)
      when page["url"] == "/"
        [compact(common.merge("@type" => "ProfilePage", "mainEntity" => ref(person_id(base)),
                              "about" => ref(person_id(base)),
                              "primaryImageOfPage" => abs(base, profile["photo"])))]
      when page["url"] == "/about/"
        [compact(common.merge("@type" => "AboutPage", "mainEntity" => ref(person_id(base)),
                              "about" => ref(person_id(base))))]
      when page["url"] == "/blog/"
        [compact(common.merge("@type" => "CollectionPage", "mainEntity" => ref(blog_id(base)))), blog(site, base)]
      when page["url"] == "/talks/"
        [compact(common.merge("@type" => "CollectionPage", "about" => ref(person_id(base)),
                              "mainEntity" => item_list(talks(profile, base))))]
      when page["url"] == "/teaching/"
        [compact(common.merge("@type" => "CollectionPage", "about" => ref(person_id(base)),
                              "mainEntity" => item_list(courses(profile, base))))]
      when page["layout"] == "tag_page"
        name = "Posts tagged #{page["tag"]}"
        posts = Array(page["posts"]).map { |post|
          { "@type" => "BlogPosting", "@id" => abs(base, post["url"]), "url" => abs(base, post["url"]), "headline" => post["title"] }
        }
        [compact(common.merge("@type" => "CollectionPage", "name" => name,
                              "description" => "#{posts.size} posts about #{page["tag"]} on #{site.config["title"]}'s blog",
                              "isPartOf" => ref(blog_id(base)), "mainEntity" => item_list(posts))),
         breadcrumbs(base, [["Home", "#{base}/"], ["Blog", "#{base}/blog/"], ["Topics", "#{base}/tags/"], [name, url]])]
      when page["url"] == "/tags/"
        [compact(common.merge("@type" => "CollectionPage", "isPartOf" => ref(blog_id(base)))),
         breadcrumbs(base, [["Home", "#{base}/"], ["Blog", "#{base}/blog/"], ["Topics", url]])]
      else
        [compact(common.merge("@type" => "WebPage"))]
      end
    end

    def blog(site, base)
      recent = site.posts.docs.reject(&:draft?).last(10).reverse
      {
        "@type" => "Blog",
        "@id" => blog_id(base),
        "url" => "#{base}/blog/",
        "name" => "#{site.config["title"]}'s blog",
        "description" => site.config["tagline"] || site.config["description"],
        "inLanguage" => site.config["lang"] || "en",
        "author" => ref(person_id(base)),
        "publisher" => ref(person_id(base)),
        "blogPost" => recent.map { |post|
          {
            "@type" => "BlogPosting",
            "@id" => abs(base, post.url),
            "headline" => post.data["title"],
            "url" => abs(base, post.url),
            "datePublished" => post.date.iso8601,
          }
        },
      }
    end

    def posting(site, page, base, url)
      site_author = site.config.dig("author", "name")
      authors = Array(page["author"]).reject { |a| a.to_s.strip.empty? }
      author_nodes = authors.map { |name|
        if name == site_author
          ref(person_id(base))
        else
          compact({ "@type" => "Person", "name" => name, "url" => page["author_url"] })
        end
      }
      author_nodes = [ref(person_id(base))] if author_nodes.empty?

      words = page["content"].to_s.gsub(/<[^>]+>/, " ").split.size
      image = page["image"].is_a?(Hash) ? page["image"]["path"] : page["image"]
      image ||= page["thumbnail"] || "/assets/static-pages/yaro-cindy.jpg"
      published = page["date"]
      modified = page["modified_date"] || published

      node = {
        "@type" => "BlogPosting",
        "@id" => url,
        "url" => url,
        "mainEntityOfPage" => { "@type" => "WebPage", "@id" => url },
        "headline" => page["title"],
        "description" => page["description"],
        "datePublished" => iso(published),
        "dateModified" => iso(modified),
        "wordCount" => words,
        "timeRequired" => "PT#{[words / 200, 1].max}M",
        "inLanguage" => site.config["lang"] || "en",
        "author" => author_nodes.size == 1 ? author_nodes.first : author_nodes,
        "publisher" => ref(person_id(base)),
        "image" => abs(base, image),
        "keywords" => Array(page["tags"]).empty? ? nil : Array(page["tags"]),
        "articleSection" => Array(page["tags"]).first,
        "isPartOf" => ref(blog_id(base)),
        "license" => "https://www.gnu.org/licenses/agpl-3.0.html",
        "isAccessibleForFree" => true,
      }
      if page["md_url"]
        node["encoding"] = {
          "@type" => "MediaObject",
          "encodingFormat" => "text/markdown",
          "contentUrl" => abs(base, page["md_url"]),
          "description" => "Raw Markdown source of this post",
        }
      end
      if (id = page["youtube_id"])
        # uploadDate is "when this media object was uploaded to this site",
        # which is the post's date.
        node["video"] = {
          "@type" => "VideoObject",
          "name" => page["title"],
          "description" => page["description"] || page["title"],
          "thumbnailUrl" => "https://i.ytimg.com/vi/#{id}/hqdefault.jpg",
          "uploadDate" => iso(published),
          "embedUrl" => "https://www.youtube-nocookie.com/embed/#{id}",
          "url" => "https://www.youtube.com/watch?v=#{id}",
        }
      end

      [compact(node), breadcrumbs(base, [["Home", "#{base}/"], ["Blog", "#{base}/blog/"], [page["title"], url]])]
    end

    def talks(profile, base)
      Array(profile["talks"]).map { |t|
        compact({
          "@type" => "CreativeWork",
          "name" => t["title"],
          "url" => t["url"],
          "description" => "#{t["kind"]} at #{t["event"]} #{t["year"]}",
          "dateCreated" => t["year"]&.to_s,
          "image" => t["thumb"] && abs(base, t["thumb"]),
          "author" => ref(person_id(base)),
        })
      }
    end

    def courses(profile, base)
      Array(profile["courses"]).map { |c|
        compact({
          "@type" => "Course",
          "name" => c["title"],
          "url" => c["url"],
          "description" => c["what"],
          "image" => c["image"] && abs(base, c["image"]),
          "provider" => ref(person_id(base)),
          "author" => ref(person_id(base)),
        })
      }
    end

    def item_list(items)
      {
        "@type" => "ItemList",
        "numberOfItems" => items.size,
        "itemListElement" => items.each_with_index.map { |item, i|
          { "@type" => "ListItem", "position" => i + 1, "item" => item }
        },
      }
    end

    def breadcrumbs(base, crumbs)
      {
        "@type" => "BreadcrumbList",
        "itemListElement" => crumbs.each_with_index.map { |(name, item), i|
          { "@type" => "ListItem", "position" => i + 1, "name" => name, "item" => item }
        },
      }
    end

    def iso(time)
      return nil if time.nil?

      time.respond_to?(:iso8601) ? time.iso8601 : Time.parse(time.to_s).iso8601
    end

    def compact(hash)
      hash.reject { |_, v| v.nil? || v == "" || v == [] }
    end
  end

  class Tag < Liquid::Tag
    def render(context)
      site = context.registers[:site]
      page = context["page"]
      json = JSON.generate(StructuredData.graph(site, page))
      # A "</script>" inside any string would end the element early.
      %(<script type="application/ld+json">#{json.gsub("</", "<\\/")}</script>)
    end
  end
end

Liquid::Template.register_tag("structured_data", StructuredData::Tag)

# Drop jekyll-seo-tag's own JSON-LD block (see the comment at the top).
SEO_TAG_JSON_LD = %r{<script type="application/ld\+json">(?:(?!</script>).)*</script>\s*(?=<!-- End Jekyll SEO tag -->)}m

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output_ext == ".html" && doc.output&.include?("<!-- End Jekyll SEO tag -->")

  doc.output = doc.output.sub(SEO_TAG_JSON_LD, "")
end
