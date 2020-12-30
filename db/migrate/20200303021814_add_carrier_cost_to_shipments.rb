class AddCarrierCostToShipments < ActiveRecord::Migration[6.0]
  def change
    add_monetize :shipments, :carrier_cost
  end
end
