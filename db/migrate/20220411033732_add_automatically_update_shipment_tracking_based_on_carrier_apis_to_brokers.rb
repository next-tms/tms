# frozen_string_literal: true

class AddAutomaticallyUpdateShipmentTrackingBasedOnCarrierApisToBrokers < ActiveRecord::Migration[7.0]
  def change
    add_column :brokers, :automatically_update_shipment_tracking_based_on_carrier_apis, :boolean, default: true
  end
end
