class AddWebsiteUsernameToBrokerCarriers < ActiveRecord::Migration[6.1]
  def change
    add_column :broker_carriers, :website_username, :string
  end
end
