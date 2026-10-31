class AddRequiresShipmentDeliveryBeforeReceivableToBrokerCustomer < ActiveRecord::Migration[7.0]
  def up
    add_column :broker_customers, :requires_shipment_delivery_before_receivable, :boolean, default: true

    BrokerCustomer.update_all(requires_shipment_delivery_before_receivable: false)
  end

  def down
    remove_column :broker_customers, :requires_shipment_delivery_before_receivable, :boolean
  end
end
