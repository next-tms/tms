class AddNotifyToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :notify, :boolean
  end
end
