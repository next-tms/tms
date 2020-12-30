class AddReceiverAddressToShipments < ActiveRecord::Migration[5.1]
  def change
    add_reference :shipments, :receiver_address, foreign_key: { to_table: :addresses }
  end
end
