class RemoveLinesFromShipments < ActiveRecord::Migration[5.1]
  def change
    remove_column :shipments, :lines, :text
  end
end
