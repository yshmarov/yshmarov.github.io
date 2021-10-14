encrypted credentials


https://edgeguides.rubyonrails.org/active_record_encryption.html


Rails 7 added


```
bin/rails db:encryption:init
```
will generate
```
active_record_encryption:
  primary_key: 1qRx9LKs1ON5gbk0q5Affs898O0S0sXo
  deterministic_key: pCgz9AgTkwO8zcn3hrZBL6tbNVQyxGvL
  key_derivation_salt: pOIy8FEWO3hVpt1f05LKuWETU1uOICPb
```
add the generated encryption keys to `credentials.yml`


Rails.application.credentials.dig(:active_record_encryption)
Rails.application.credentials.dig(:active_record_encryption, :primary_key)
Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)
Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt)


class Inbox < ApplicationRecord
	# default
	# better security, impossible to query
  encrypts :description

  # possible to query
  # same string would get same encrypted hash
	# deterministic_key not needed
  encrypts :description, deterministic: true
end

### STRING should be 510 characters long





****

Thoughts on security:

* If someone steals the database, he will also need the encryption keys.
* You should use different credentials for development and production.
* Do not use production database in dev
* Do not share prod env key ...


