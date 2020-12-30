class AddShipmentToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_reference :addresses, :shipment, foreign_key: true
  end
end
