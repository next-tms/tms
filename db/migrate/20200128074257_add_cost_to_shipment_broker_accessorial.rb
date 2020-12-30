class AddCostToShipmentBrokerAccessorial < ActiveRecord::Migration[6.0]
  def change
    add_monetize :shipment_broker_accessorials, :cost
  end
end
