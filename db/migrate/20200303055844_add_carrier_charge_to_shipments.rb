class AddCarrierChargeToShipments < ActiveRecord::Migration[6.0]
  def change
    add_monetize :shipments, :carrier_charge
  end
end
