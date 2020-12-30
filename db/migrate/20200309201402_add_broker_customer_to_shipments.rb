class AddBrokerCustomerToShipments < ActiveRecord::Migration[6.0]
  def change
    add_reference :shipments, :broker_customer, foreign_key: true
  end
end
