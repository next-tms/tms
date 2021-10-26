# frozen_string_literal: true

class AddBrokerLoadIdUniqueIndexOnShipments < ActiveRecord::Migration[6.1]
  def change
    add_index :shipments, [:broker_id, :load_id], unique: true
  end
end
