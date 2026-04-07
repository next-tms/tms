class AddIgnoreBrokerCarrierBolRequiresTrackingNumberToBrokers < ActiveRecord::Migration[7.0]
  def change
    add_column :brokers, :ignore_broker_carrier_bol_requires_tracking_number, :boolean, default: false
  end
end
