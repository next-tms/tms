class AddReceiverContactPhoneToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :receiver_contact_phone, :string
  end
end
