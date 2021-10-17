request params


_helper.rb
```
  def mobile_device
    agent = request.user_agent
    return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/
    return "desktop"
  end
```


<%= mobile_device %>
<hr>

<%= request.user_agent %>
<hr>

<%= request.env.each do |header| %>
  <hr>
  <%= header %>
<% end %>
<br>
<%= request.ip %>
<br>
<%= request.remote_ip %>
