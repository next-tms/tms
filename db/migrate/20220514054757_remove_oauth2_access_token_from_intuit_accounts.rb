class RemoveOauth2AccessTokenFromIntuitAccounts < ActiveRecord::Migration[7.0]
  def change
    remove_column :intuit_accounts, :oauth2_access_token, :string
  end
end
