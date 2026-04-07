class AddPublicNotesToShipments < ActiveRecord::Migration[6.1]
  def change
    add_column :shipments, :public_notes, :text
  end
end
