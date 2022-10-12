class AddRequiresShipmentShipperReferenceOnReceivablesOnBrokerCustomer < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_customers, :requires_shipment_shipper_reference_on_receivables, :boolean, default: false
  end
end
