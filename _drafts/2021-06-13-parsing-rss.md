
https://guides.rubyonrails.org/action_view_helpers.html#atomfeedhelper

https://blog.corsego.com/feed.xml

[RSS reading and writing](https://github.com/ruby/rss)

Gemfile
```ruby
gem 'rss'
```
controller
```ruby
@episodes = []
url = 'http://feeds.backtracks.fm/feeds/indiehackers/indiehackers/feed.xml?1588905169'
URI.open(url) do |rss|
  @episodes = RSS::Parser.parse(rss, false).items
end
```
view
```ruby
<% @episodes.each do |ep| %>
  <div class="episode">
    <%= link_to ep.title, ep.link %>
    <br />
    <span class="text-muted"><%= ep.pubDate %></span>
    <br />
    <span><%= ep.description.html_safe %></span>
    <br />
    <audio controls="true" preload="none" src="<%= ep.enclosure.url %>"></audio>
  </div>
  <hr>
<% end %>
<% if @episodes.length == 0 %>
  <i>No episodes available.</i>
<% end %>
```

https://pjbelo.medium.com/building-an-xml-api-with-rails-79379b305a6
https://stackoverflow.com/questions/3951235/how-do-i-make-an-rss-atom-feed-in-rails-3

