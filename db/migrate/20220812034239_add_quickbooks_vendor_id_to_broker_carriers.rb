# frozen_string_literal: true

class AddQuickbooksVendorIdToBrokerCarriers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_carriers, :quickbooks_vendor_id, :integer, index: true
  end
end
