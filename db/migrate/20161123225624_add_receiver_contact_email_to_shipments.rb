class AddReceiverContactEmailToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :receiver_contact_email, :string
  end
end
