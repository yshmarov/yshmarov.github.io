---
layout: post
title: 'TLDR: Rails 7 Active Record Encryption'
author: Yaroslav Shmarov
tags: 
- ruby on rails
- credentials
- encryption
- secrets
thumbnail: /assets/thumbnails/encryption-lock.png
---

**PII** (personal identifiable information) and **PHI** (personal health information) is considered very sensitive, and if you are processing it, there can be **requirements** to protect it.

Rails 7 added [Active Record Encryption](https://edgeguides.rubyonrails.org/active_record_encryption.html), that replaces gems like [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted). It is a long-awaited default feature by organizations that have high data-security standarts and requirements.

Why you need attribute encryption:
* If someone steals your database dump, they won't have easy access to the encrypted attributes (they will also need the encryption keys)
* Encrypted columns are automatically filtered in logs

Security-oriented static code analysis tools like [bearer/bearer](https://github.com/bearer/bearer) can hint on what attributes you should encrypt:

![bearer-attribute-encryption-scan-results](/assets/images/bearer-attribute-encryption-scan-results.png)

### 1. Encrypt attributes

If you run this command in the console

```s
bin/rails db:encryption:init
```

it will generate a few lines, that you should add to `credentials.yml`:

```
active_record_encryption:
  primary_key: 1qRx9LKs1ON5gbk0q5Affs898O0S0sXo
  deterministic_key: pCgz9AgTkwO8zcn3hrZBL6tbNVQyxGvL
  key_derivation_salt: pOIy8FEWO3hVpt1f05LKuWETU1uOICPb
```

Try to encrypt attributes:

```ruby
# app/models/client.rb
class Client < ApplicationRecord
  encrypts :name, deterministic: true, downcase: true # string
  encrypts :annual_income # integer
  encrypts :date_of_birth # datetime
  encrypts :health_condition # text
  has_rich_text :description, encrypted: true # ActionText
end
```

### 2. Problems that you will encounter:

#### 2.1. Encryptable data types:

You can really encrypt only `string` and `text` fields (because we store a long hashed string on the database level).

It is recommended to store encryptable attributes as `text`, not `string`.

If you want to encrypt an `integer` or `datetime`, **you will get errors**. You have to store encryptable data as `text`.

I think it is quite safe to change column type from integer to text. If you do so, further encryption will be easy.

```ruby
class StoreIntegersAsText < ActiveRecord::Migration[7.0]
  def change
    change_column :clients, :annual_income, :text
  end
end
```

#### 2.2. Querying encrypted data:

Only if you use **deterministic** encryption, you will be able to query the database, but only for an exact match like `Client.find_by(username: 'yarotheslav')`.

#### 2.3. [Encrypting existing data](https://edgeguides.rubyonrails.org/active_record_encryption.html#support-for-unencrypted-data)

If you want to add encryption to existing attributes that already store data, you will get an error.

Add these lines to `application.rb` to allow encrypted and unencrypted data to co-exist:

```ruby
# config/application.rb
  config.active_record.encryption.support_unencrypted_data = true
  config.active_record.encryption.extend_queries = true
```

### 3. Useful commands

```ruby
client = Client.last
# encrypt all attributes that use encrypts
client.encrypt
# decrypt all attributes that use encrypts
client.decrypt
# get the value that is stored in the database, not the decrypted version
client.ciphertext_for :sexual_orientation
# is this attribute encrypted?
client.encrypted_attribute? :sexual_orientation
# encrypt all records
Client.all.map(&:encrypt)
# decrypt all records
Client.all.map(&:decrypt)
```

Example:

![encrypted-attributes-api](/assets/images/encrypted-attributes-api.png)

Summary:
- Encrypting attributes adds a layer of complexity, but sometimes external factors force you to do it. 
- I currently use Active Record Encryption to encrypt `ApiToken.secret_token` in an app.
