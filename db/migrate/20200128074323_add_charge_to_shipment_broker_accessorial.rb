class AddChargeToShipmentBrokerAccessorial < ActiveRecord::Migration[6.0]
  def change
    add_monetize :shipment_broker_accessorials, :charge
  end
end
