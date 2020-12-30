class AddDeliveryHoursEndToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :delivery_hours_end, :string
  end
end
