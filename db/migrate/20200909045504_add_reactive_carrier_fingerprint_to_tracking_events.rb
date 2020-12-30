class AddReactiveCarrierFingerprintToTrackingEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :tracking_events, :reactive_carrier_fingerprint, :string
  end
end
