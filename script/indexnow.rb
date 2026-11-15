# frozen_string_literal: true

# Tells IndexNow (Bing, Yandex, Seznam, Naver; Bing's index also feeds ChatGPT
# search and Copilot) which URLs changed in a deploy, so new and updated posts
# are recrawled in minutes instead of whenever the crawler next comes round.
# https://www.indexnow.org/documentation
#
# Usage: ruby script/indexnow.rb <before-sha> <after-sha>
# Run from the deploy workflow after GitHub Pages has published. Never fails the
# deploy: a ping that does not land just means the usual crawl picks it up.

require "json"
require "net/http"
require "uri"

HOST = "blog.superails.com"
KEY_FILE = Dir.glob("[0-9a-f]" * 32 + ".txt").first or abort "IndexNow key file not found"
KEY = File.basename(KEY_FILE, ".txt")

before, after = ARGV
changed =
  if before.to_s.empty? || before.match?(/\A0+\z/)
    []
  else
    `git diff --name-only --diff-filter=AM #{before} #{after} 2>/dev/null`.split("\n")
  end

urls = changed.filter_map { |path|
  case path
  when %r{\A_posts/\d{4}-\d{2}-\d{2}-(.+)\.(md|markdown)\z} then "https://#{HOST}/#{Regexp.last_match(1)}"
  when "_data/profile.yml", "index.md" then "https://#{HOST}/"
  when "about.md" then "https://#{HOST}/about/"
  when "talks.html" then "https://#{HOST}/talks/"
  when "teaching.html" then "https://#{HOST}/teaching/"
  end
}
# A new or changed post also changes the lists that point at it.
urls += ["https://#{HOST}/blog/", "https://#{HOST}/llms.txt"] if urls.any? { |u| !u.end_with?("/") }
urls.uniq!

if urls.empty?
  puts "IndexNow: no content URLs changed, nothing to submit."
  exit 0
end

payload = { host: HOST, key: KEY, keyLocation: "https://#{HOST}/#{KEY}.txt", urlList: urls }
uri = URI("https://api.indexnow.org/indexnow")
begin
  res = Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json; charset=utf-8")
  puts "IndexNow: HTTP #{res.code} for #{urls.size} URLs"
  urls.each { |u| puts "  #{u}" }
rescue StandardError => e
  puts "IndexNow: request failed (#{e.class}: #{e.message})"
end
