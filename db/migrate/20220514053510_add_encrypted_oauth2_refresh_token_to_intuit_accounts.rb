# frozen_string_literal: true

class AddEncryptedOauth2RefreshTokenToIntuitAccounts < ActiveRecord::Migration[7.0]
  def up
    add_column :intuit_accounts, :encrypted_oauth2_refresh_token, :string

    say 'populate(:intuit_accounts, :encrypted_oauth2_refresh_token)'
    IntuitAccount.find_each do |intuit_account|
      intuit_account.update(encrypted_oauth2_refresh_token: intuit_account.oauth2_refresh_token)
    end
  end

  def down
    remove_column :intuit_accounts, :encrypted_oauth2_refresh_token, :string
  end
end
