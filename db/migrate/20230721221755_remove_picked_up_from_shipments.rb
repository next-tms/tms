# frozen_string_literal: true

class RemovePickedUpFromShipments < ActiveRecord::Migration[7.0]
  def up
    remove_column(:shipments, :picked_up, :boolean)
  end

  def down
    add_column(:shipments, :picked_up, :boolean)

    say('populate(:shipments, :picked_up)')
    Shipment.where(picked_up_at: nil).find_each { |shipment| shipment.update!(picked_up: false) }
    Shipment.where.not(picked_up_at: nil).find_each { |shipment| shipment.update!(picked_up: true) }
  end
end
