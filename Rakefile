# frozen_string_literal: true

require "rake"
require "nokogiri"
require "json"
require "yaml"
require "date"
require "uri"
require "set"

SITE_DIR = "_site"

def read_file(path)
  File.read(path, encoding: "utf-8")
end

desc "Build the Jekyll site"
task :build do
  sh "bundle exec #{jekyll_bin} build"
end

desc "Run smoke tests against the built site"
task :smoke do
  abort "#{SITE_DIR}/ not found. Run `rake build` first." unless Dir.exist?(SITE_DIR)

  errors = []
  checks_passed = 0

  # --- 1. Key files exist and are non-empty ---
  %w[
    index.html
    404.html
    feed.xml
    sitemap.xml
    about/index.html
  ].each do |path|
    file = File.join(SITE_DIR, path)
    unless File.exist?(file) && File.size(file) > 0
      errors << "Missing or empty: #{path}"
    end
  end
  puts "  OK: All key files present"
  checks_passed += 1

  # --- 2. Homepage renders post list ---
  index_html = read_file(File.join(SITE_DIR, "index.html"))
  post_count = index_html.scan(/<li>/).size
  if post_count < 10
    errors << "Homepage has too few list items (#{post_count}), expected 10+"
  else
    puts "  OK: Homepage has #{post_count} list items"
    checks_passed += 1
  end

  if index_html.include?('class="post-list"')
    puts "  OK: Homepage contains post-list"
    checks_passed += 1
  else
    errors << "Homepage missing post-list class"
  end

  # --- 3. Post pages have expected content ---
  post_files = Dir.glob(File.join(SITE_DIR, "*.html")).reject { |f|
    %w[index.html 404.html].include?(File.basename(f))
  }
  sampled = post_files.sample(5)
  sampled.each do |post_path|
    name = File.basename(post_path)
    content = read_file(post_path)

    errors << "#{name}: missing post-title"   unless content.include?("post-title")
    errors << "#{name}: missing post-content"  unless content.include?("post-content")
    errors << "#{name}: missing site-header"   unless content.include?("site-header")
    errors << "#{name}: missing site-footer"   unless content.include?("site-footer")
  end
  puts "  OK: #{sampled.size} post pages have correct structure"
  checks_passed += 1

  # --- 4. Navigation renders ---
  if index_html.include?("site-nav") && index_html.include?("nav-item")
    puts "  OK: Navigation present"
    checks_passed += 1
  else
    errors << "Homepage missing navigation (site-nav / nav-item)"
  end

  # --- 5. Tag pages exist ---
  tag_dir = File.join(SITE_DIR, "tag")
  if Dir.exist?(tag_dir)
    tag_pages = Dir.glob(File.join(tag_dir, "**/*.html"))
    if tag_pages.size < 5
      errors << "Too few tag pages (#{tag_pages.size})"
    else
      puts "  OK: #{tag_pages.size} tag pages generated"
      checks_passed += 1
    end
  else
    errors << "No tag/ directory found"
  end

  # --- 6. Feed is valid XML with entries ---
  feed_path = File.join(SITE_DIR, "feed.xml")
  feed = Nokogiri::XML(read_file(feed_path))
  entries = feed.xpath("//xmlns:entry", "xmlns" => "http://www.w3.org/2005/Atom")
  if entries.empty?
    errors << "feed.xml has no <entry> elements"
  else
    puts "  OK: feed.xml has #{entries.size} entries"
    checks_passed += 1
  end

  # --- 7. Sitemap has URLs ---
  sitemap_path = File.join(SITE_DIR, "sitemap.xml")
  sitemap = Nokogiri::XML(read_file(sitemap_path))
  urls = sitemap.xpath("//xmlns:url", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
  if urls.size < 100
    errors << "sitemap.xml has too few URLs (#{urls.size})"
  else
    puts "  OK: sitemap.xml has #{urls.size} URLs"
    checks_passed += 1
  end

  # --- 8. No Liquid errors in output ---
  liquid_errors = []
  Dir.glob(File.join(SITE_DIR, "**/*.html")).each do |f|
    content = read_file(f)
    if content.include?("Liquid error") || content.include?("Liquid syntax error")
      liquid_errors << f.sub("#{SITE_DIR}/", "")
    end
  end
  if liquid_errors.any?
    errors << "Liquid errors in: #{liquid_errors.first(5).join(', ')}"
  else
    puts "  OK: No Liquid errors in any page"
    checks_passed += 1
  end

  # --- 9. No broken layouts (pages with zero content) ---
  empty_pages = Dir.glob(File.join(SITE_DIR, "**/*.html")).select { |f|
    File.size(f) < 100 && !File.basename(f).start_with?("sw-")
  }
  if empty_pages.any?
    errors << "Near-empty pages: #{empty_pages.first(5).map { |f| f.sub("#{SITE_DIR}/", "") }.join(', ')}"
  else
    puts "  OK: No suspiciously empty pages"
    checks_passed += 1
  end

  # --- 10. CSS was compiled ---
  css_files = Dir.glob(File.join(SITE_DIR, "assets/css/**/*.css"))
  if css_files.any? && css_files.all? { |f| File.size(f) > 100 }
    puts "  OK: CSS compiled (#{css_files.size} files)"
    checks_passed += 1
  else
    errors << "No compiled CSS found or CSS files are empty"
  end

  # --- 11. Every indexed post has a .md companion ---
  search_path = File.join(SITE_DIR, "search.json")
  md_files = Dir.glob(File.join(SITE_DIR, "*.md"))
  index = []
  begin
    index = JSON.parse(read_file(search_path))
  rescue StandardError => e
    errors << "search.json is not valid JSON: #{e.message}"
  end

  if index.size < 300
    errors << "search.json has too few entries (#{index.size}), expected 300+"
  elsif md_files.size != index.size
    errors << "#{md_files.size} .md files but #{index.size} search.json entries; they must match"
  else
    puts "  OK: #{md_files.size} .md files, one per indexed post"
    checks_passed += 1
  end

  missing_md = index.reject { |e| File.exist?(File.join(SITE_DIR, "#{e["url"].to_s.sub(%r{\A/}, "")}.md")) }
  if missing_md.any?
    errors << "No .md for: #{missing_md.first(5).map { |e| e["url"] }.join(', ')}"
  else
    puts "  OK: every indexed post resolves to a .md"
    checks_passed += 1
  end

  # --- 12. search.json rows carry the fields agents are promised ---
  bad_rows = index.reject { |e|
    e["title"].to_s != "" && e["url"].to_s != "" && e["markdown_url"].to_s != "" && e["bytes"].is_a?(Integer)
  }
  if bad_rows.any?
    errors << "search.json rows missing title/url/markdown_url/bytes: #{bad_rows.size}"
  else
    puts "  OK: search.json rows complete (title, url, markdown_url, bytes)"
    checks_passed += 1
  end

  # --- 13. Newest-first ordering (regressed once; site search renders this order) ---
  dates = index.map { |e| Date.parse(e["date"]) rescue nil }.compact
  if dates.size == index.size && dates.each_cons(2).all? { |a, b| a >= b }
    puts "  OK: search.json is newest-first"
    checks_passed += 1
  else
    errors << "search.json is not newest-first (first=#{index.first&.dig("date")}, last=#{index.last&.dig("date")})"
  end

  llms_txt = File.exist?(File.join(SITE_DIR, "llms.txt")) ? read_file(File.join(SITE_DIR, "llms.txt")) : ""
  llms_dates = llms_txt.scan(/^- \[.*?\]\(\S+\): (\d{4}-\d{2}-\d{2})/).flatten
  if llms_dates.size >= 300 && llms_dates.each_cons(2).all? { |a, b| a >= b }
    puts "  OK: llms.txt lists #{llms_dates.size} posts, newest-first"
    checks_passed += 1
  else
    errors << "llms.txt ordering/count wrong (#{llms_dates.size} posts, first=#{llms_dates.first})"
  end

  # --- 14. .md files are Markdown source, not converted HTML, with valid front matter ---
  required_fm = %w[title author date canonical_url markdown_url description license]
  fm_errors = []
  md_files.sample(25).each do |path|
    name = File.basename(path)
    body = read_file(path)
    m = body.match(/\A---\n(.*?)\n---\n(.*)\z/m)
    next fm_errors << "#{name}: no front matter" unless m

    begin
      fm = YAML.safe_load(m[1])
      missing = required_fm.reject { |k| fm[k].to_s != "" }
      fm_errors << "#{name}: missing #{missing.join(',')}" if missing.any?
    rescue StandardError => e
      fm_errors << "#{name}: unparseable front matter (#{e.class})"
    end

    content = m[2].to_s
    fm_errors << "#{name}: looks like HTML, not Markdown" if content.lstrip.start_with?("<")
    # {% raw %} blocks legitimately emit {{ }}, so only flag tags that prove
    # Liquid never ran.
    fm_errors << "#{name}: unrendered Liquid tag" if content =~ /\{%\s*(post_url|link)\s/
  end
  if fm_errors.any?
    errors << "Bad .md files: #{fm_errors.first(5).join('; ')}"
  else
    puts "  OK: sampled .md files are valid Markdown with complete front matter"
    checks_passed += 1
  end

  # --- 15. Drafts leak into nothing an agent or crawler is pointed at ---
  draft_slugs = Dir.glob("_drafts/*.md").map { |f|
    File.basename(f, ".md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
  }
  # Compare whole URL paths, not substrings. Two earlier attempts false
  # positived: the draft "request-js" is a tail of the published post
  # "drag-and-drop-stimulus-request-js", and it is also a legitimate tag page at
  # /tag/request-js.html.
  advertised = sitemap.xpath("//xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
                      .map { |n| URI.parse(n.text).path rescue nil }
  advertised += index.flat_map { |e| [e["url"], e["markdown_url"]] }
  %w[llms.txt llms-full.txt].each do |f|
    path = File.join(SITE_DIR, f)
    next unless File.exist?(path)

    advertised += read_file(path).scan(%r{https?://[^/\s)"']+(/[^\s)"'<>]*)}).flatten
  end
  advertised = advertised.compact.map { |p|
    p.sub(%r{\A/}, "").sub(%r{/\z}, "").sub(/\.md\z/, "")
  }.to_set

  leaks = draft_slugs.select { |slug| advertised.include?(slug) }
                     .map { |slug| "#{slug} advertised" }
  leaks += draft_slugs.select { |slug| File.exist?(File.join(SITE_DIR, "#{slug}.md")) }
                      .map { |slug| "#{slug}.md written" }
  if leaks.any?
    errors << "Draft leaked: #{leaks.first(5).join(', ')}"
  else
    puts "  OK: none of #{draft_slugs.size} drafts appear among #{advertised.size} advertised URLs"
    checks_passed += 1
  end

  # --- 16. Post bodies are not duplicated (a Liquid tag inside an HTML comment
  #         still renders, which shipped every post twice) ---
  dupes = sampled.reject { |f| read_file(f).scan(/<article/).size == 1 }
  if dupes.any?
    errors << "Post body not exactly once in: #{dupes.first(3).map { |f| File.basename(f) }.join(', ')}"
  else
    puts "  OK: #{sampled.size} post pages contain exactly one <article>"
    checks_passed += 1
  end

  # --- 17. No conflicting duplicate social meta tags ---
  meta_dupes = sampled.filter_map { |f|
    counts = read_file(f).scan(/(?:name|property)="((?:twitter|og):[a-z:]+)"/).flatten
                         .tally.reject { |k, v| v == 1 || k == "og:image:alt" }
    "#{File.basename(f)}: #{counts.keys.join(',')}" if counts.any?
  }
  if meta_dupes.any?
    errors << "Duplicate meta tags: #{meta_dupes.first(3).join('; ')}"
  else
    puts "  OK: no duplicate og:/twitter: meta tags"
    checks_passed += 1
  end

  # --- 18. Content Signals policy is published ---
  robots = File.exist?(File.join(SITE_DIR, "robots.txt")) ? read_file(File.join(SITE_DIR, "robots.txt")) : ""
  if robots =~ /^Content-Signal:\s*\S+/ && robots.include?("Sitemap:")
    puts "  OK: robots.txt publishes a Content-Signal and a Sitemap"
    checks_passed += 1
  else
    errors << "robots.txt missing Content-Signal or Sitemap directive"
  end

  # --- Report ---
  puts
  if errors.empty?
    puts "All #{checks_passed} smoke tests passed."
  else
    puts "FAILURES (#{errors.size}):"
    errors.each { |e| puts "  - #{e}" }
    abort
  end
end

desc "Build and run smoke tests"
task test: [:build, :smoke]

task default: :test

# --- helpers ---

def jekyll_bin
  spec = Gem::Specification.find_by_name("jekyll")
  File.join(spec.gem_dir, "exe", "jekyll")
rescue Gem::MissingSpecError
  "jekyll"
end
