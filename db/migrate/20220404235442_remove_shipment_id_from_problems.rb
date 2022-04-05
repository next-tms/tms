# frozen_string_literal: true

class RemoveShipmentIdFromProblems < ActiveRecord::Migration[7.0]
  def change
    remove_column :problems, :shipment_id, :integer
  end
end
