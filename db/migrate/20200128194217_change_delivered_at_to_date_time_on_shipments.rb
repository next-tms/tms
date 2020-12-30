class ChangeDeliveredAtToDateTimeOnShipments < ActiveRecord::Migration[6.0]
  def change
    change_column :shipments, :delivered_at, :datetime
  end
end
