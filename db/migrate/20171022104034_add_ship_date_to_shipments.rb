class AddShipDateToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :ship_date, :date
  end
end
