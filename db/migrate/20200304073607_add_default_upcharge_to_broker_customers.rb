class AddDefaultUpchargeToBrokerCustomers < ActiveRecord::Migration[6.0]
  def change
    add_monetize :broker_customers, :default_upcharge
  end
end
