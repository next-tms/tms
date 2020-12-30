class AddPromisedDeliveryByToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :promised_delivery_by, :datetime
  end
end
