class AddLoadIdToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :load_id, :int
  end
end
