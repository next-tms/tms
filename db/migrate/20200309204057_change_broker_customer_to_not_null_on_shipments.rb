class ChangeBrokerCustomerToNotNullOnShipments < ActiveRecord::Migration[6.0]
  def change
    change_column_null :shipments, :broker_customer_id, false
  end
end
