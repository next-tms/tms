class AddBrokerNotesToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :broker_notes, :text
  end
end
