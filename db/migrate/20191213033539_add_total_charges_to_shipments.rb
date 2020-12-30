class AddTotalChargesToShipments < ActiveRecord::Migration[5.2]
  def change
    add_monetize :shipments, :total_charges, default: nil
  end
end
