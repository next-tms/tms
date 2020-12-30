class AddDeliverByToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :deliver_by, :date
  end
end
