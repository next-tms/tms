class AddQuoteOnlyToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :quote_only, :boolean, default: false
  end
end
