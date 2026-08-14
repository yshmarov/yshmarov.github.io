# frozen_string_literal: true

# Makes the blog cheap and lossless for LLMs and AI agents to read.
#
# 1. Serves the raw Markdown source of every post at <post-url>.md, which is the
#    form llmstxt.org recommends ("the extension replaced by `.md`"). An agent
#    that fetches the HTML instead gets a lossy Markdown *reconstruction*, with
#    code fences guessed at and headings rewritten.
# 2. Exposes the same Markdown to Liquid as `post.md_source`, so llms-full.txt
#    can embed posts with their code fences intact.
# 3. Fills in `page.description` for posts that don't set one, so jekyll-seo-tag
#    stops using the first line of the post as the entire summary. An explicit
#    `description:` in front matter always wins; this is only a fallback.
#
# The Liquid in a post body (`{% post_url %}` and friends) is rendered once here,
# so the Markdown that ships has real URLs in it. That is the reason this is a
# local plugin rather than the jekyll-aeo gem, which covers similar ground:
# its auto mode converts rendered HTML back to Markdown for any source
# containing Liquid (the lossy path), its md2dotmd mode strips Liquid tags and
# so leaves `{% post_url %}` links empty, it has no notion of drafts, and it
# wants to generate robots.txt itself, which would drop our Content Signals.
#
# Invariants this file is responsible for are asserted by `rake smoke` in CI.

module LlmReadable
  FRONT_MATTER = /\A---\s*\r?\n.*?\r?\n---\s*\r?\n/m
  MAX_DESCRIPTION = 160
  FULL_TEXT_POSTS = 30
  LICENSE = "GNU AGPL v3. Credit Yaroslav Shmarov and link the canonical URL."

  # A page emitted verbatim. The internal ".mdsrc" extension matches no
  # converter, so Jekyll's Identity converter passes the body through untouched;
  # the real extension comes back via #output_ext.
  class SourcePage < Jekyll::PageWithoutAFile
    def initialize(site, permalink, body)
      @output_ext = File.extname(permalink)
      dir = File.dirname(permalink)
      dir = "" if dir == "/"

      super(site, site.source, dir, "#{File.basename(permalink, @output_ext)}.mdsrc")

      @data = {
        "layout" => nil,
        "permalink" => permalink,
        "sitemap" => false,
        # The generator already ran Liquid over this body. A second pass would
        # re-evaluate anything a {% raw %} block deliberately emitted.
        "render_with_liquid" => false,
      }
      self.content = body
    end

    attr_reader :output_ext
  end

  class << self
    # Post body with front matter stripped and Liquid rendered, still Markdown.
    def markdown_body(site, post)
      raw = File.read(post.path, **site.file_read_opts).sub(FRONT_MATTER, "")
      payload = site.site_payload
      payload["page"] = post.to_liquid
      info = {
        :registers => { :site => site, :page => payload["page"] },
        :strict_filters => false,
        :strict_variables => false,
      }
      site.liquid_renderer.file(post.path).parse(raw).render!(payload, info)
    rescue StandardError => e
      Jekyll.logger.warn "LLM Readable:", "Liquid failed for #{post.relative_path}: #{e.message}"
      raw.to_s
    end

    # The .md files get read standalone, detached from the site, so root-relative
    # links and images in them would dangle. Make them absolute.
    def absolutize(site, body)
      body.gsub(%r{(!?\[[^\]]*\]\()(/(?!/)[^)\s]*)}) { "#{::Regexp.last_match(1)}#{absolute(site, ::Regexp.last_match(2))}" }
    end

    # A standalone Markdown file: front matter an agent can trust, then the post
    # under its own H1 (post bodies start at H2).
    def markdown_document(site, post, body)
      author = Array(post.data["author"] || site.config.dig("author", "name")).join(", ")
      fields = {
        "title" => post.data["title"].to_s,
        "author" => author,
        "date" => post.date.strftime("%Y-%m-%d"),
        "canonical_url" => absolute(site, post.url),
        "markdown_url" => absolute(site, "#{post.url}.md"),
        "description" => post.data["description"].to_s,
        "tags" => Array(post.data["tags"]),
        "license" => LICENSE,
      }
      fields["video_url"] = "https://www.youtube.com/watch?v=#{post.data["youtube_id"]}" if post.data["youtube_id"]

      front = fields.reject { |_, v| v.nil? || v == "" || v == [] }
                    .map { |key, value| "#{key}: #{value.to_json}" }
                    .join("\n")

      "---\n#{front}\n---\n\n# #{post.data["title"]}\n\n#{body.strip}\n"
    end

    # Plain-text summary of a Markdown body, for <meta name="description">.
    # Deliberately greedy across the opening lines: posts here often open with a
    # one-line teaser ("HTML to PDF in Ruby is weird:") followed by the list that
    # actually says something.
    def description_for(markdown)
      text = sanitize(markdown)
      lines = prose_lines(text)
      # A handful of posts open straight into a code fence or are nothing but a
      # Markdown table. Fall back to headings and table cells for those.
      lines = fallback_lines(text) if lines.empty?
      truncate(lines.join(" "))
    end

    private

    def sanitize(markdown)
      text = markdown.dup
      text.gsub!(/^ {0,3}```.*?^ {0,3}```/m, " ")   # fenced code
      text.gsub!(/^ {0,3}~~~.*?^ {0,3}~~~/m, " ")
      text.gsub!(/<!--.*?-->/m, " ")                # comments
      text.gsub!(/\{%.*?%\}/m, " ")                 # leftover Liquid
      text.gsub!(/\{\{.*?\}\}/m, " ")
      text.gsub!(/!\[[^\]]*\]\([^)]*\)/, " ")       # images
      text.gsub!(/\[([^\]]*)\]\([^)]*\)/, '\1')     # links -> link text
      text.gsub!(/<[^>]+>/, " ")                    # inline HTML
      text.delete!("`")                             # code spans
      text.gsub!(/\*+/, "")                         # bold/italic. Underscores are
                                                    # left alone: snake_case is
                                                    # everywhere in these posts.
      text
    end

    def prose_lines(text)
      collect(text) do |line|
        next if line.start_with?("#", ">", "|", "{:")  # headings, quotes, tables, kramdown attrs
        line
      end
    end

    def fallback_lines(text)
      collect(text) do |line|
        next if line.start_with?("{:")
        line.sub(/\A#+\s*/, "").sub(/\A>\s*/, "").gsub("|", " ").squeeze(" ").strip
      end
    end

    def collect(text)
      collected = []
      text.each_line do |raw|
        line = raw.strip
        next if line.empty?
        next if line.match?(/\A[-=*|:\s]{3,}\z/)  # horizontal rules, table separators

        line = yield(line.sub(/\A(?:[-*+]|\d+\.)\s+/, "").strip)  # list markers
        next if line.nil? || line.empty?

        collected << line
        break if collected.sum(&:length) > MAX_DESCRIPTION
      end
      collected
    end

    def truncate(text)
      text = text.gsub(/\s+/, " ").strip
      return text if text.length <= MAX_DESCRIPTION

      window = text[0, MAX_DESCRIPTION + 1]
      boundary = window.rindex(/[.!?;](?=\s)/)
      return text[0..boundary].strip if boundary && boundary > 80

      "#{window[0, window.rindex(" ") || MAX_DESCRIPTION].strip.chomp(",")}…"
    end

    def absolute(site, path)
      "#{site.config["url"]}#{path}"
    end
  end

  class Generator < Jekyll::Generator
    safe true
    # After jekyll-og-image and the tagging generators have had their say.
    priority :low

    def generate(site)
      site.config["llm_full_text_posts"] = FULL_TEXT_POSTS

      # Unpublished work stays out of everything an LLM is pointed at. Drafts are
      # only in site.posts at all when Jekyll runs with --drafts, but that is
      # exactly how this blog is served locally, so filter rather than assume.
      drafts, posts = site.posts.docs.partition(&:draft?)
      # Keep drafts out of the sitemap too, so a --drafts preview build never
      # advertises them to a crawler.
      drafts.each { |draft| draft.data["sitemap"] = false }

      posts.each do |post|
        body = LlmReadable.absolutize(site, LlmReadable.markdown_body(site, post))

        post.data["md_source"] = body
        post.data["md_url"] = "#{post.url}.md"
        # Exact byte size of the .md, for search.json. Deliberately not a token
        # estimate: a bytes-per-token constant differs by model family, so an
        # integer "token count" would imply precision it does not have. An agent
        # can divide by ~4 itself if it wants a rough figure.
        post.data["md_bytes"] = body.bytesize
        post.data["description"] = LlmReadable.description_for(body) if blank?(post.data["description"])

        site.pages << SourcePage.new(
          site, "#{post.url}.md", LlmReadable.markdown_document(site, post, body)
        )
      end

      # llms.txt, llms-full.txt and search.json iterate this instead of
      # site.posts, so a --drafts build cannot leak a draft into them either.
      #
      # site.posts.docs is chronological, but Liquid's site.posts is newest
      # first. Sort the same way Jekyll's SiteDrop#posts does, so ordering and
      # tie-breaking match: llms-full.txt takes the *recent* 30, not the oldest
      # 30, and search.json keeps the order the search UI renders in.
      site.config["llm_posts"] = posts.sort { |a, b| b <=> a }.map(&:to_liquid)
    end

    private

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end
