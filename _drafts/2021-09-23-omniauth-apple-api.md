


Gemfile
```
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-apple'
```





/findsubreddit/app/models/user.rb
```
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :omniauthable, omniauth_providers: [:google_oauth2, :apple]
```



/config/initializers/devise.rb
```
  config.omniauth :apple, Rails.application.credentials.dig(:apple, :client_id), '',
    {
      scope: 'email name',
      team_id: Rails.application.credentials.dig(:apple, :team_id),
      key_id: Rails.application.credentials.dig(:apple, :key_id),
      # pem: Rails.application.credentials.dig(:apple, :private_key),
      pem: ENV['APPLE_PRIVATE_KEY'],
      provider_ignores_state: true
    }
```
credentials.yml
```
apple:
    client_id: com.findsubreddit
    team_id: C4TW8RQ4U6
    key_id: VD78F6DS48
    private_key: "-----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg45MNXqGErFlSev3G
    p6RCoxa+Iy5iDk5T0woj1p3aH2GgCgYIKoZIzj0DAQehRANCAAR6IsqnTX7Av1FD
    Z+XHXjBnR3NgyVbDQf2WF7wwlt+NNDVmjUkLcc8/FoQjAyzFhh4qltNuUd2xIrgS
    n6iEBRno
    -----END PRIVATE KEY-----"
```