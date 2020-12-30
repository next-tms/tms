class AllowNullBrokerCustomerIdOnRates < ActiveRecord::Migration[6.0]
  def change
    change_column_null :rates, :broker_customer_id, true
  end
end
