class AddShipmentStringPatternsToBrokerCustomers < ActiveRecord::Migration[5.1]
  def change
    add_column :broker_customers, :shipment_string_patterns, :text
  end
end
