class AddChargesConfirmedToShipment < ActiveRecord::Migration[7.0]
  def change
    add_column :shipments, :charges_confirmed, :boolean, default: false
  end
end
