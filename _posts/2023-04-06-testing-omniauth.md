---
layout: post
title: Test Omniauth authentication (github, azure)
author: Yaroslav Shmarov
tags: 
- ruby on rails
- omniauth
- testing
- minitest
- github
- azure
thumbnail: /assets/thumbnails/oauth.png
youtube_id: kW-AEo6V15M
---

### 1. Mock oAuth responce with Faker

If you are using `gem "faker"` you can mock [a few popular omniauth payloads](https://github.com/faker-ruby/faker/blob/main/doc/default/omniauth.md).

The omniauth gem allows you to mock a successful authentication using `OmniAuth.config.mock_auth`.

`:github` omniauth example:

```ruby
# test/test_helper.rb
module OmniauthGithubHelper
  def login_with_github_oauth
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(Faker::Omniauth.github)
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end
end
```

Now, to authenticate in a **controller** test you can run:

```ruby
login_with_github_oauth
post user_github_omniauth_callback_path
```

In a **system** test you can do:

```ruby
login_with_github_oauth
visit user_github_omniauth_callback_path
```

### 2. Mock oAuth responce **without** Faker

Unfortunately, not all omniauth payload are covered by Faker.
In this case, you can introduce a mock omniauth payload directly within your app:

```ruby
# test/fixtures/azure_activedirectory_v2.json
{"provider": "azure_activedirectory_v2",
 "uid": "c9546ade-d57e-414e-8e99",
 "info": {"name": "Yaro Shm", "email": "yaro@superails.com", "nickname": "yaro", "first_name": "Yaro", "last_name": "Shm"},
 "credentials": 
  {"token": "eyJ0eXAiOi",
   "expires_at": 1680218216,
   "expires": true},
 "extra": 
  {"raw_info": 
    {"aud": "00000003-0000-0000-c000-000000000000",
     "iss": "https://sts.windows.net/7a306d84-95aa-48d4-85d6/",
     "iat": 1680213810,
     "nbf": 1680213810,
     "exp": 1680258227,
     "email": "yaro@superails.com",
     "name": "Yaro Shm",
     "oid": "c9546ade-d57e-414e-8e99",
     "preferred_username": "yaro@superails.com",
     "rh": "0.AU4AhG0weqqV.",
     "sub": "kqf4_v-TPdpt5",
     "tid": "7a306d84-95aa",
     "uti": "jYe4xjm75EW",
     "ver": "1.0",
     "acct": 0,
     "acr": "1",
     "aio": "AVQAq/8TAAAA/y2xH6WocplaNttawB6iaOboLXz4j",
     "amr": ["pwd", "mfa"],
     "app_displayname": "superails",
     "appid": "4cc835b1-cfb0-4a24-90ea",
     "appidacr": "1",
     "family_name": "Shm",
     "given_name": "Yaro",
     "idtyp": "user",
     "ipaddr": "77.205.16.21",
     "platf": "5",
     "puid": "1003200283",
     "scp": "Contacts.Read email openid profile User.Read",
     "signin_state": ["kmsi"],
     "tenant_region_scope": "EU",
     "unique_name": "yaro@superails.com",
     "upn": "yaro@superails.com",
     "wids": ["b79fbf4d-3ef9-4689-8143"],
     "xms_st": {"sub": "QTfz4TlRSckh1yZfnzt0r6lHbec0"},
     "xms_tcdt": 1643572,
     "xms_tdbr": "EU"}}}
```

Now, create a helper method to authenticate using the above omniauth payload:

```ruby
# test/test_helper.rb
module OmniauthMicrosoftHelper
  def login_with_azure_activedirectory_v2_oauth
    file = File.read('test/fixtures/azure_activedirectory_v2.json')
    parsed_file = JSON.parse(file)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:azure_activedirectory_v2] = parsed_file
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:azure_activedirectory_v2]
  end
end
```

### 3. Write tests

Finally, test the authentication in a **controller** test:

```ruby
# test/controllers/omniauth_login_controller_test.rb
require 'test_helper'

class OmniauthLoginTest < ActionDispatch::IntegrationTest
  include OmniauthMicrosoftHelper

  test 'auth success' do
    assert_not User.pluck(:email).include?(JSON.parse(File.read('test/fixtures/azure_activedirectory_v2.json'))['info']['email'])
    login_with_azure_activedirectory_v2_oauth
    post user_azure_activedirectory_v2_omniauth_callback_path

    assert_response :redirect
    assert_redirected_to root_path

    assert User.pluck(:email).include?(JSON.parse(File.read('test/fixtures/azure_activedirectory_v2.json'))['info']['email'])
    assert_equal controller.current_user, User.last
  end

  test 'auth failure' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:azure_activedirectory_v2] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:azure_activedirectory_v2]
    post user_azure_activedirectory_v2_omniauth_callback_path

    assert_response :redirect
    assert_redirected_to root_path
    assert_nil controller.current_user
  end
end
```

Based on the [Official docs for testing omniauth](https://github.com/omniauth/omniauth/wiki/Integration-Testing)

That's it!
