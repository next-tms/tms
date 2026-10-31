class AddQuickbooksVendorIdToBrokerCarriers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_carriers, :quickbooks_vendor_id, :integer
    add_index :broker_carriers, :quickbooks_vendor_id
  end
end
