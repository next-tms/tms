class AddIndexToBrokerNotesOnShipments < ActiveRecord::Migration[6.0]
  def change
    add_index :shipments, :broker_notes
  end
end
