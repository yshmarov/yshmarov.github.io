# frozen_string_literal: true

# Makes the blog cheap and lossless for LLMs and AI agents to read.
#
# 1. Serves the raw Markdown source of every post at <post-url>.md. An agent
#    that fetches the HTML gets a lossy Markdown *reconstruction* of the post,
#    with code fences guessed at and headings often rewritten. This serves the
#    post itself, at roughly a third of the tokens.
# 2. Exposes the same Markdown to Liquid as `post.md_source`, so llms-full.txt
#    and the per-year shards can embed posts with their code fences intact.
# 3. Fills in `page.description` for posts that don't set one, so jekyll-seo-tag
#    stops using the first line of the post as the entire summary.
#
# The Liquid in a post body (`{% post_url %}` and friends) is rendered once here,
# so the Markdown that ships has real URLs in it.

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

    # Rough token count: the static-host equivalent of the x-markdown-tokens
    # header Cloudflare returns on negotiated Markdown responses, which an agent
    # can use to size a context window or pick a chunking strategy. 4.04 bytes
    # per token is measured from that header on a comparable Markdown document.
    def token_estimate(body)
      (body.bytesize / 4.04).round
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
        "estimated_tokens" => token_estimate(body),
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
        post.data["md_tokens"] = LlmReadable.token_estimate(body)
        post.data["description"] = LlmReadable.description_for(body) if blank?(post.data["description"])

        site.pages << SourcePage.new(
          site, "#{post.url}.md", LlmReadable.markdown_document(site, post, body)
        )
      end

      # llms.txt and llms-full.txt iterate this instead of site.posts, so a
      # --drafts build cannot leak a draft into them either.
      site.config["llm_posts"] = posts.map(&:to_liquid)

      generate_year_shards(site, posts)
    end

    private

    # llms-full.txt only carries recent posts, so the archive would otherwise be
    # reachable only one post at a time. One bounded file per year fixes that.
    def generate_year_shards(site, posts)
      by_year = posts.group_by { |post| post.date.year }
      site.config["llm_years"] = by_year.keys.sort.reverse

      by_year.each do |year, posts|
        site.pages << SourcePage.new(site, "/llms/#{year}.txt", year_shard(site, year, posts))
      end
    end

    def year_shard(site, year, posts)
      header = <<~HEADER
        # #{site.config["title"]} — every post from #{year}

        #{posts.size} posts, full Markdown source, newest first.
        License: #{LlmReadable::LICENSE}
        Index of all posts: #{site.config["url"]}/llms.txt
      HEADER

      bodies = posts.sort_by(&:date).reverse.map do |post|
        LlmReadable.markdown_document(site, post, post.data["md_source"])
      end

      "#{header}\n---\n\n#{bodies.join("\n---\n\n")}"
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end
