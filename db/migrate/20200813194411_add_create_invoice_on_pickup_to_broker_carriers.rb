class AddCreateInvoiceOnPickupToBrokerCarriers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_carriers, :create_invoice_on_pickup, :boolean
  end
end
