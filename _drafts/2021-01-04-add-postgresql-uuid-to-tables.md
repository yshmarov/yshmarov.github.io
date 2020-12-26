https://guides.rubyonrails.org/v5.0/active_record_postgresql.html#uuid
https://pawelurbanek.com/uuid-order-rails
https://itnext.io/using-uuids-to-your-rails-6-application-6438f4eeafdf

class EnableUuid < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'
  end
end

    create_table :users do |t|
    create_table :users, id: :uuid do |t|

       t.references :owner, type: :uuid


   create_table "account_invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
