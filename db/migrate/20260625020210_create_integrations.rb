class CreateIntegrations < ActiveRecord::Migration[8.0]
  class Integration < ActiveRecord::Base
    self.table_name = 'integrations'

    encrypts :credentials
  end

  class IntuitAccount < ActiveRecord::Base
    self.table_name = 'intuit_accounts'

    encrypts :encrypted_oauth2_access_token
    encrypts :encrypted_oauth2_refresh_token
  end

  def up
    create_table(:integrations) do |t|
      t.jsonb :credentials, null: false

      t.string :kind, null: false
      t.string :name, null: false

      t.timestamps

      t.index %i[kind name], unique: true
    end

    IntuitAccount.find_each do |intuit_account|
      Integration.create!(
        created_at: intuit_account.created_at,
        credentials: {
          access_token: intuit_account.encrypted_oauth2_access_token,
          access_token_expires_at: intuit_account.oauth2_access_token_expires_at,
          realm_id: intuit_account.realm_id,
          refresh_token: intuit_account.encrypted_oauth2_refresh_token,
          refresh_token_expires_at: intuit_account.oauth2_refresh_token_expires_at
        },
        kind: 'quickbooks',
        name: 'default',
        updated_at: intuit_account.updated_at,
      )
    end
  end

  def down = drop_table(:integrations)
end
