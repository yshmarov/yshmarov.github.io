# frozen_string_literal: true

require "rake"
require "nokogiri"

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
