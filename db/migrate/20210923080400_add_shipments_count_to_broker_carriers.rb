# frozen_string_literal: true

class AddShipmentsCountToBrokerCarriers < ActiveRecord::Migration[6.1]
  def change
    add_column :broker_carriers, :shipments_count, :integer
    add_index :broker_carriers, :shipments_count
  end
end
