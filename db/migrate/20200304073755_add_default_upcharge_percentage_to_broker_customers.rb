class AddDefaultUpchargePercentageToBrokerCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_customers, :default_upcharge_percentage, :float
  end
end
