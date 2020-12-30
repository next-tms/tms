class AddQuoteIdToShipments < ActiveRecord::Migration[5.2]
  def change
    add_column :shipments, :quote_id, :string
  end
end
