class AddReceiverNameToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :receiver_name, :string
  end
end
