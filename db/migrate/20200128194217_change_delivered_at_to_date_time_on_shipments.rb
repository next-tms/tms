class ChangeDeliveredAtToDateTimeOnShipments < ActiveRecord::Migration[6.0]
  def up
    change_column :shipments, :delivered_at, :datetime
  end
end
