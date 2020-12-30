class AddCustomerToShipments < ActiveRecord::Migration[5.1]
  def change
    add_reference :shipments, :customer, foreign_key: true
  end
end
