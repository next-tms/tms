class AddLostOnToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :lost_on, :date
  end
end
