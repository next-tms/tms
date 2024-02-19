# frozen_string_literal: true

class AddFingerprintToShipments < ActiveRecord::Migration[7.1]
  def change
    add_column(:shipments, :fingerprint, :string)
  end
end
