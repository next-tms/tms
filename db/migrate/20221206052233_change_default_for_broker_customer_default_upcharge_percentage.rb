class ChangeDefaultForBrokerCustomerDefaultUpchargePercentage < ActiveRecord::Migration[7.0]
  def up
    change_column_default :broker_customers, :default_upcharge_percentage, 0
    BrokerCustomer.where(default_upcharge_percentage: nil).update_all(default_upcharge_percentage: 0)
  end

  def down
    change_column_default :broker_customers, :default_upcharge_percentage, nil
    BrokerCustomer.where(default_upcharge_percentage: 0).update_all(default_upcharge_percentage: nil)
  end
end
