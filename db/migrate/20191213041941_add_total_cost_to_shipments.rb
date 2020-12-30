class AddTotalCostToShipments < ActiveRecord::Migration[5.2]
  def change
    add_monetize :shipments, :total_cost, default: nil
  end
end
