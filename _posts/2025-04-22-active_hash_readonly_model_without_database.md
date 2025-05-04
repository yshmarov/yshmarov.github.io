---
layout: post
title: Readonly Models without database
author: Yaroslav Shmarov
tags: rails active_hash
thumbnail: /assets/thumbnails/rails-logo.png
---

Use Ruby hashes as readonly datasources for ActiveRecord-like models.

Define data in YML

```yml
# config/models/platforms.yml
- id: instagram
  name: Instagram
  status: active
  logo: instagram-logo.svg
  url_pattern: https?://(?:www\.)?instagram\.com/
- id: x
  name: X
  status: active
  logo: x-logo.svg
  url_pattern: https?://(?:www\.)?x\.com/|https?://(?:www\.)?twitter\.com/
- id: youtube
  name: YouTube
  status: active
  logo: youtube-logo.svg
  url_pattern: https?://(?:www\.)?youtube\.com/
```

Add [gem active_hash](https://github.com/active-hash/active_hash)

```sh
bundle add active_hash
```

Load the YML in a model:

```ruby
# app/models/platform.rb
class Platform < ActiveHash::Base
  include ActiveHash::Associations

  self.data = YAML.load_file("#{Rails.root}/config/models/platforms.yml")

  has_many :campaign_platforms, dependent: :restrict_with_error
  # has_many :campaign_platforms, dependent: :restrict_with_error, class_name: "Platform", foreign_key: :platform_id
  has_many :campaigns, through: :campaign_platforms

  def label_string
    name
  end

  scope :active, -> { where(status: :active) }
end
```

Defign foreign key:

```ruby
  add_column :campaign_platforms, :platform_id, :string, null: false
  add_index :campaign_platforms, :platform_id
```

Define associations

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
class Campaign < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  has_many :campaign_platforms, dependent: :destroy
  has_many :platforms, through: :campaign_platforms
```

For the data to be updated, you might have to restart the server.
