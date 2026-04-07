class AddAutomaticallyAuthorizeReceivablesToBrokers < ActiveRecord::Migration[7.0]
  def change
    add_column :brokers, :automatically_authorize_receivables, :boolean, default: false
  end
end
