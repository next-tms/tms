class CreateIntuitAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :intuit_accounts do |t|
      t.datetime :oauth2_access_token_expires_at
      t.datetime :oauth2_refresh_token_expires_at

      t.references :broker

      t.text :oauth2_access_token
      t.text :oauth2_refresh_token
      t.text :realm_id

      t.timestamps
    end
  end
end
