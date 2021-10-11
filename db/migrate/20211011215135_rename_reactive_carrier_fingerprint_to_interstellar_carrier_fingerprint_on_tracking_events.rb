# frozen_string_literal: true

class RenameReactiveCarrierFingerprintToInterstellarCarrierFingerprintOnTrackingEvents < ActiveRecord::Migration[6.1]
  def change
    rename_column :tracking_events, :reactive_carrier_fingerprint, :interstellar_carrier_fingerprint
  end
end
