class AddDispatchedToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :dispatched, :boolean, default: false
  end
end
