class AddValueToShipments < ActiveRecord::Migration[6.0]
  def change
    add_monetize :shipments, :value
  end
end
