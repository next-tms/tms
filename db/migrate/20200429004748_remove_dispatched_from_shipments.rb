class RemoveDispatchedFromShipments < ActiveRecord::Migration[6.0]
  def up
    remove_column :shipments, :dispatched
  end
end
