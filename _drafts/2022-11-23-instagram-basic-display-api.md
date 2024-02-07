https://developers.facebook.com/docs/instagram-basic-display-api/getting-started/

Instagram Basic Display API

### 1. Authorization window

https://www.instagram.com/accounts/manage_access/

```ruby
# config/routes.rb
  get 'instagram/authorize', to: "instagram#authorize"
  get 'instagram/callback', to: "instagram#callback"
```

```ruby
<%= link_to "Instagram login", instagram_authorize_path %>
```

```ruby
# app/controllers/instagram_controller.rb
class InstagramController < ApplicationController
  CLIENT_ID = Rails.application.credentials.dig(:instagram, :client_id).to_s
  CLIENT_SECRET = Rails.application.credentials.dig(:instagram, :client_secret).to_s
  REDIRECT_URI = 'https://insta2site.herokuapp.com/'
  # include Rails.application.routes.url_helpers
  # REDIRECT_URI = url_for(instagram_callback_path, base_url: true)

  def authorize
    authorize_url = 'https://api.instagram.com/oauth/authorize'
    redirect_to "#{authorize_url}?client_id=#{CLIENT_ID}&redirect_uri=#{REDIRECT_URI}&scope=user_profile,user_media&response_type=code",
                allow_other_host: true
  end

  def callback
    # Log in with instagram -> get authorization code via redirect callback.
    cookies[:auth_code] = params[:code]
    return head :bad_request unless code
  end
end
```

### 2. Exchange authorization code for bearer token

```ruby
# app/controllers/instagram_controller.rb
class InstagramController < ApplicationController
# class GetTokenService
end
```

### 3. Get user data

```ruby
# config/routes.rb
  get 'me', to: "profile#me"
  get 'me/media', to: "profile#media"
```

```ruby
# app/controllers/profile_controller.rb
class ProfileController < ApplicationController
  def me
    access_token = cookies[:long_lived_access_token]
    return unless long_lived_access_token.present?

    response = Faraday.get("#{graph_base_url}/me") do |req|
      req.headers = headers,
      req.params = user_params(access_token)
    end

    render json: response.body
  end

  def media
    access_token = cookies[:long_lived_access_token]
    return unless long_lived_access_token.present?

    response = Faraday.get("#{graph_base_url}/me/media") do |req|
      req.headers = headers,
      req.params = media_params(access_token)
    end

    render json: response.body
  end

  private

  def user_params(access_token)
    {
      fields: 'id,username,account_type,media_count',
      access_token: long_lived_access_token
    }
  end

  def media_params(access_token)
    {
      fields: 'id,caption,media_type,media_url,permalink,thumbnail_url,timestamp,username',
      access_token:
    }
  end

  def graph_base_url
    'https://graph.instagram.com'
  end

  def headers
    { Accept: 'application/json' }
  end
end
```

That's it!

### Other

Refresh token expiring in less than 25 hours
https://www.instagram.com/oauth/authorize?client_id=1072477516433078&scope=user_profile,user_media&response_type=code&redirect_uri=https://app.convertkit.com/instagram/connect
0. Api dashboard
https://developers.facebook.com/apps/804997997508152/roles/roles/
1. Instagram Authorization window
=> Access code
https://developers.facebook.com/docs/instagram-basic-display-api/overview#instagram-user-access-tokens
4. User fields
User
https://developers.facebook.com/docs/instagram-basic-display-api/reference/user#fields
User Media
https://developers.facebook.com/docs/instagram-basic-display-api/reference/user/media
5. Paginated results
https://developers.facebook.com/docs/graph-api/results

# Deauthorize callback URL
# Data Deletion Request URL
