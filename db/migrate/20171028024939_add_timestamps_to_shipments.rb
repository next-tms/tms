class AddTimestampsToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :created_at, :datetime
    add_column :shipments, :updated_at, :datetime
  end
end
