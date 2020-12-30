class RemoveDispatchedFromShipments < ActiveRecord::Migration[6.0]
  def change
    remove_column :shipments, :dispatched
  end
end
