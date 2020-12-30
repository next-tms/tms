class AddBolNotesToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :bol_notes, :text
  end
end
