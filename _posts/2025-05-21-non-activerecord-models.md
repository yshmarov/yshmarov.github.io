---
layout: post
title: ActiveRecord models without database
author: Yaroslav Shmarov
tags: activerecord
thumbnail: /assets/static-pages/yaro-avatar.png
---

# Use Ruby hashes as readonly datasources for ActiveRecord-like models.

https://github.com/active-hash/active_hash

gem "active_hash"

```yml
# config/models/platforms.yml
- id: instagram
  name: Instagram
  status: draft
  logo: instagram-logo.svg
  url_pattern: https?://(?:www\.)?instagram\.com/
- id: x
  name: X
  status: draft
  logo: x-logo.svg
  url_pattern: https?://(?:www\.)?x\.com/|https?://(?:www\.)?twitter\.com/
- id: youtube
  name: YouTube
  status: active
  logo: youtube-logo.svg
  url_pattern: https?://(?:www\.)?youtube\.com/
```

```ruby
# app/models/platform.rb
class Platform < ActiveHash::Base
  include ActiveHash::Associations

  self.data = YAML.load_file("#{Rails.root}/config/models/platforms.yml")

  has_many :campaign_platforms, dependent: :restrict_with_error
  # has_many :campaign_platforms, dependent: :restrict_with_error, class_name: "Platform", foreign_key: :platform_id
  has_many :campaigns, through: :campaign_platforms
end
```

```ruby
# app/models/campaign_platform.rb
class CampaignPlatform < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to :campaign
  belongs_to :platform, class_name: "Platform", foreign_key: "platform_id"
end
```

```ruby
# app/models/campaign.rb
  extend ActiveHash::Associations::ActiveRecordExtensions
  has_many :campaign_platforms, dependent: :destroy
  has_many :platforms, through: :campaign_platforms

  # Have to define these manually because Platforms is an active_hash
  def platform_ids
    campaign_platforms.map(&:platform_id)
  end

  def platform_ids=(ids)
    self.campaign_platforms = ids.map { |id| campaign_platforms.find_or_initialize_by(platform_id: id) }
  end
```

That's it!
