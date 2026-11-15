# frozen_string_literal: true

require "nokogiri"

# Markdown twins for the non-post pages: /index.md, /about.md, /talks.md and
# /teaching.md.
#
# Posts get their .md from the Markdown their author wrote (llm_readable.rb).
# These pages have no such source: the homepage, /talks/ and /teaching/ are
# Liquid over _data/profile.yml. Their rendered HTML *is* the source of truth,
# so the twin is converted from it, after rendering. That keeps the twin from
# ever drifting from the page, at the cost of a converter that only needs to
# understand the handful of elements these layouts emit.
#
# "Who is this person and what has he done" is the question the homepage
# answers, and the one an agent is most likely to be asked about this site, so
# it deserves the same cheap, lossless path the posts have.
#
# Asserted by `rake smoke`.
module PageMarkdown
  TWINS = {
    "/" => "/index.md",
    "/about/" => "/about.md",
    "/talks/" => "/talks.md",
    "/teaching/" => "/teaching.md",
  }.freeze

  # Generated pages are routed through LlmReadable::SourcePage, which writes its
  # content verbatim.
  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      TWINS.each do |url, md_path|
        source = site.pages.find { |p| p.url == url }
        next unless source

        source.data["md_url"] = md_path
        # Always re-render the source so the twin has output to convert, even
        # under `jekyll serve --incremental`.
        source.data["regenerate"] = true

        twin = LlmReadable::SourcePage.new(site, md_path, "")
        twin.data["twin_of"] = url
        twin.data["regenerate"] = true
        site.pages << twin
      end
    end
  end

  # Turns a page's <main> into Markdown. Block elements become paragraphs,
  # headings and lists; everything else is flattened to inline text.
  class Converter
    BLOCK = %w[div section article header footer main nav aside figure p h1 h2 h3 h4 h5 h6 ul ol blockquote table hr pre].freeze
    SKIP = %w[script style noscript svg button input form template iframe].freeze
    # Secondary text (dates, venues, counts) reads better parenthesised.
    ASIDE_CLASS = /\b(landing-date|landing-work-meta|landing-card-proof|landing-location)\b/

    def initialize(base_url, page_url)
      @base = base_url
      @page_url = page_url
    end

    def convert(html)
      main = Nokogiri::HTML(html).at_css("main .wrapper") or return ""
      blocks(main).join("\n\n").gsub(/\n{3,}/, "\n\n").strip + "\n"
    end

    private

    def skip?(node)
      return true if node.comment?
      return false unless node.element?

      SKIP.include?(node.name) ||
        node["aria-hidden"] == "true" || node["hidden"] ||
        node["class"].to_s.match?(/\b(anchor|confirm-badge)\b/)
    end

    def block?(node)
      node.element? && (BLOCK.include?(node.name) || card?(node))
    end

    # A link wrapping several lines of text (a course card) is an item of its
    # own, not inline text.
    def card?(node)
      node.name == "a" && link_parts(node).size > 1
    end

    def link_parts(node)
      parts = node.element_children.reject { |c| skip?(c) || squish(c.text).empty? }
      parts = parts.first.element_children.reject { |c| skip?(c) || squish(c.text).empty? } while parts.size == 1 && parts.first.element_children.size > 1
      parts
    end

    # Children as a list of Markdown blocks. Runs of inline nodes between block
    # children are gathered into one paragraph.
    def blocks(node)
      out = []
      run = []
      flush = lambda {
        text = squish(join_inline(run))
        out << text unless text.empty?
        run.clear
      }
      node.children.each do |child|
        next if skip?(child)

        if block?(child)
          flush.call
          out.concat(block(child))
        else
          run << child
        end
      end
      flush.call
      out
    end

    def block(node)
      case node.name
      when /\Ah([1-6])\z/
        text = squish(inline_children(node))
        text.empty? ? [] : ["#{"#" * ::Regexp.last_match(1).to_i} #{text}"]
      when "ul", "ol"
        [list(node, node.name == "ol", 0)].reject(&:empty?)
      when "blockquote"
        blocks(node).map { |b| b.gsub(/^/, "> ") }
      when "hr"
        ["---"]
      when "pre"
        ["```\n#{node.text.rstrip}\n```"]
      when "a"
        ["- #{link(node)}"]
      else
        blocks(node)
      end
    end

    def list(node, ordered, depth)
      items = node.element_children.select { |c| c.name == "li" }.reject { |li| skip?(li) }
      items.each_with_index.map { |li, i|
        marker = ordered ? "#{i + 1}." : "-"
        nested = li.element_children.select { |c| %w[ul ol].include?(c.name) }
        text = squish(join_inline(li.children.reject { |c| nested.include?(c) || skip?(c) }))
        line = "#{"  " * depth}#{marker} #{text}"
        sub = nested.map { |n| list(n, n.name == "ol", depth + 1) }
        ([line] + sub).join("\n")
      }.join("\n")
    end

    def inline_children(node)
      join_inline(node.children.reject { |c| skip?(c) })
    end

    # Layouts strip whitespace between links with {%- -%}, which would glue
    # "[GitHub](..)[LinkedIn](..)" together. Separate element siblings that
    # touch.
    def join_inline(nodes)
      out = +""
      prev = nil
      nodes.each do |node|
        piece = inline(node)
        next if piece.empty?

        if prev&.element? && node.element? && !out.end_with?(" ") && !piece.start_with?(" ")
          out << (prev.name == "a" && node.name == "a" ? " · " : " ")
        end
        out << piece
        prev = node
      end
      out
    end

    def inline(node)
      return "" if skip?(node)
      return node.text.gsub(/\s+/, " ") if node.text?
      return "" unless node.element?

      case node.name
      when "a" then link(node)
      when "strong", "b" then wrap(inline_children(node), "**")
      when "em", "i" then wrap(inline_children(node), "*")
      when "code" then "`#{node.text}`"
      when "br" then " "
      when "img"
        alt = node["alt"].to_s.strip
        alt.empty? ? "" : "![#{alt}](#{absolute(node["src"])})"
      else
        text = inline_children(node)
        if node["class"].to_s.match?(ASIDE_CLASS) && !squish(text).empty?
          " (#{squish(text)}) "
        elsif block?(node)
          " #{text} "
        else
          # Spans laid out as separate lines (title, description, stats) need
          # a separator once flattened.
          node.name == "span" && node.parent&.name == "a" ? " #{text} ·" : text
        end
      end
    end

    # A link wrapping several spans (a course card) keeps only the first as the
    # link text and lets the rest follow it.
    def link(node)
      href = absolute(node["href"])
      parts = link_parts(node)
      if parts.size > 1
        title = squish(inline_children(parts.first))
        rest = parts.drop(1).map { |c| squish(inline(c)) }.reject(&:empty?)
        "[#{title}](#{href}): #{rest.join(" ")}"
      else
        text = squish(inline_children(node))
        text.empty? ? "" : "[#{text}](#{href})"
      end
    end

    def wrap(text, mark)
      t = squish(text)
      t.empty? ? "" : "#{mark}#{t}#{mark}"
    end

    def absolute(href)
      href = href.to_s.strip
      return "#{@base}#{@page_url}#{href}" if href.start_with?("#")
      return "#{@base}#{href}" if href.start_with?("/") && !href.start_with?("//")

      href
    end

    def squish(text)
      text.to_s.gsub(/\s+/, " ").gsub(/\s+([,.;:)])/, '\1').gsub(/\(\s+/, "(").gsub(/\s*·\s*\z/, "").strip
    end
  end

  def self.document(site, page, body)
    base = site.config["url"].to_s
    fields = {
      "title" => page.data["title"].to_s,
      "author" => site.config.dig("author", "name").to_s,
      "canonical_url" => "#{base}#{page.url}",
      "markdown_url" => "#{base}#{page.data["md_url"]}",
      "description" => page.data["description"].to_s,
      "license" => LlmReadable::LICENSE,
    }
    front = fields.reject { |_, v| v.empty? }.map { |k, v| "#{k}: #{v.to_json}" }.join("\n")
    "---\n#{front}\n---\n\n#{body}"
  end
end

Jekyll::Hooks.register :site, :post_render do |site|
  base = site.config["url"].to_s
  site.pages.each do |twin|
    url = twin.data["twin_of"] or next
    source = site.pages.find { |p| p.url == url }
    next unless source&.output

    body = PageMarkdown::Converter.new(base, url).convert(source.output)
    twin.output = PageMarkdown.document(site, source, body)
  end
end
