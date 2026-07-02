class DropIntuitAccounts < ActiveRecord::Migration[8.0]
  def change
    drop_table(:intuit_accounts) do |t|
      t.bigint :broker_id

      t.datetime :oauth2_access_token_expires_at
      t.datetime :oauth2_refresh_token_expires_at

      t.string :encrypted_oauth2_access_token
      t.string :encrypted_oauth2_refresh_token

      t.text :realm_id

      t.timestamps

      t.index :broker_id
    end
  end
end
