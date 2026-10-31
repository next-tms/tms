class AddEncryptedOauth2AccessTokenToIntuitAccounts < ActiveRecord::Migration[7.0]
  def up
    add_column :intuit_accounts, :encrypted_oauth2_access_token, :string

    say 'populate(:intuit_accounts, :encrypted_oauth2_access_token)'
    IntuitAccount.find_each { |intuit_account| intuit_account.update(encrypted_oauth2_access_token: intuit_account.oauth2_access_token) }
  end

  def down
    remove_column :intuit_accounts, :encrypted_oauth2_access_token, :string
  end
end
