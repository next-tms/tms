# frozen_string_literal: true

class RemoveOauth2RefreshTokenFromIntuitAccounts < ActiveRecord::Migration[7.0]
  def change
    remove_column :intuit_accounts, :oauth2_refresh_token, :string
  end
end
