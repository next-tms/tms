class AddBolToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :bol, :string
  end
end
