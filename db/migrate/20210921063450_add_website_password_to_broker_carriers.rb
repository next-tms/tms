class AddWebsitePasswordToBrokerCarriers < ActiveRecord::Migration[6.1]
  def change
    add_column :broker_carriers, :website_password, :string
  end
end
